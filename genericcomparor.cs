#r "nuget:BenchmarkDotNet/0.11.5"

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;
/// <summary>
/// Immutable class containing changes
/// </summary>
public sealed class ChangeResult<TLocal, TRemote>
{
    public ChangeResult(IEnumerable<TLocal> deleted, IEnumerable<Tuple<TLocal, TRemote>> changed, IEnumerable<TRemote> inserted)
    {
        Deleted = deleted;
        Changed = changed;
        Inserted = inserted;
    }

    public IEnumerable<TLocal> Deleted { get; }

    public IEnumerable<Tuple<TLocal, TRemote>> Changed { get; }

    public IEnumerable<TRemote> Inserted { get; }
}

public static class ListExtensions
{
    /// <summary>
    /// Gets the changes [Deleted, changed, inserted] comparing this collection to another.
    /// </summary>
    /// <param name="local">The source collection.</param>
    /// <param name="remote">The remote collection to comare agains.</param>
    /// <param name="keySelector">The primary key selector function</param>
    /// <returns></returns>
    //orignally extention method 
    public static ChangeResult<TSource, TSource> CompareToImpl1<TSource, TKey>(IEnumerable<TSource> local, IEnumerable<TSource> remote, Func<TSource, TKey> keySelector)
    {
        if (local == null)
            throw new ArgumentNullException("local");
        if (remote == null)
            throw new ArgumentNullException("remote");
        if (keySelector == null)
            throw new ArgumentNullException("keySelector");

        var remoteKeyValues = remote.ToDictionary(keySelector);

        var deleted = new List<TSource>();
        var changed = new List<Tuple<TSource, TSource>>();
        var localKeys = new HashSet<TKey>();

        foreach (var localItem in local)
        {
            var localKey = keySelector(localItem);
            localKeys.Add(localKey);

            /* Check if primary key exists in both local and remote 
             * and if so check if changed, if not it has been deleted
             */
            TSource changeCandidate;
            if (remoteKeyValues.TryGetValue(localKey, out changeCandidate))
            {
                if (!changeCandidate.Equals(localItem))
                    changed.Add(new Tuple<TSource, TSource>(localItem, changeCandidate));
            }
            else
            {
                deleted.Add(localItem);
            }
        }
        var inserted = remoteKeyValues
                        .Where(x => !localKeys.Contains(x.Key))
                        .Select(x => x.Value)
                        .ToList();

        return new ChangeResult<TSource, TSource>(deleted, changed, inserted);
    }

    /// <summary>
    /// Gets the changes [Deleted, changed, inserted] comparing this collection to another.
    /// </summary>
    /// <typeparam name="TSource"></typeparam>
    /// <typeparam name="TKey"></typeparam>
    /// <param name="local">The source collection.</param>
    /// <param name="remote">The remote collection to compare against.</param>
    /// <param name="keySelector">The primary key selector function</param>
    /// <returns></returns>
    public static ChangeResult<TSource, TSource> CompareToImpl2<TSource, TKey>(
        IEnumerable<TSource> local,
        IEnumerable<TSource> remote,
        Func<TSource, TKey> keySelector)
    {
        if (local == null)
        {
            throw new ArgumentNullException("local");
        }

        if (remote == null)
        {
            throw new ArgumentNullException("remote");
        }

        if (keySelector == null)
        {
            throw new ArgumentNullException("keySelector");
        }

        local = local.ToList();

        var remoteKeyValues = remote.ToDictionary(keySelector);
        var deleted = new List<TSource>(local.Count());
        var changed = new List<Tuple<TSource, TSource>>(local.Count());
        var localKeys = new HashSet<TKey>();

        Parallel.ForEach(
            local,
            localItem =>
            {
                var localKey = keySelector(localItem);

                lock (localKeys)
                {
                    localKeys.Add(localKey);
                }

                /* Check if primary key exists in both local and remote
                 * and if so check if changed, if not it has been deleted
                 */

                if (remoteKeyValues.TryGetValue(localKey, out TSource changeCandidate))
                {
                    if (changeCandidate.Equals(localItem))
                    {
                        return;
                    }

                    lock (changed)
                    {
                        changed.Add(new Tuple<TSource, TSource>(localItem, changeCandidate));
                    }
                }
                else
                {
                    lock (deleted)
                    {
                        deleted.Add(localItem);
                    }
                }
            });

        var inserted = remoteKeyValues
            .AsParallel()
            .Where(x => !localKeys.Contains(x.Key))
            .Select(x => x.Value)
            .ToList();

        return new ChangeResult<TSource, TSource>(deleted, changed, inserted);
    }


    /// <summary>
    /// Gets the changes [Deleted, changed, inserted] comparing this collection to another.
    /// </summary>
    /// <param name="local">The source collection.</param>
    /// <param name="remote">The remote collection to comare agains.</param>
    /// <param name="keySelector">The primary key selector function</param>
    /// <param name="compareFunc">Optional camparing function between 2 objects of type TSource</param>
    /// <returns>List of changes as Added, Removed and Changed items of type TSource</returns>
    public static ChangeResult<TLocal, TLocal> CompareToImpl3<TLocal, TKey>(
        IEnumerable<TLocal> local, IEnumerable<TLocal> remote, Func<TLocal, TKey> keySelector, Func<TLocal, TLocal, bool> compareFunc = null)
    {
        if (local == null)
            throw new ArgumentNullException("local");
        if (remote == null)
            throw new ArgumentNullException("remote");
        if (keySelector == null)
            throw new ArgumentNullException("keySelector");

        var remoteKeyValues = new ConcurrentDictionary<TKey, TLocal>(remote.ToDictionary(keySelector));
        var localKeyValues = new ConcurrentDictionary<TKey, TLocal>(local.ToDictionary(keySelector));
        var changed = new ConcurrentBag<Tuple<TLocal, TLocal>>();

        Parallel.ForEach(
           local,
           localItem =>
           {
               var localItemKey = keySelector(localItem);

               //1. Check if item is both in local and remote
               if (remoteKeyValues.TryRemove(localItemKey, out var remoteItemValue))
               {
                   //1.a item is in both collections -> check if they are different
                   var isItemChanged = compareFunc != null ? !compareFunc(localItem, remoteItemValue) :
                    !localItem.Equals(remoteItemValue);

                   if (isItemChanged)
                   {
                       //1.b are different -> mark a change
                       changed.Add(new Tuple<TLocal, TLocal>(localItem, remoteItemValue));
                   }

                   //1.c remove the item from local list as it's prensent in remote list too
                   //this should never return false
                   localKeyValues.TryRemove(localItemKey, out var localItemValue);
               }

               //2. if item is not in remote list means it has been removed
           });

        var deleted = localKeyValues.Values;
        var inserted = remoteKeyValues.Values;

        return new ChangeResult<TLocal, TLocal>(deleted, changed, inserted);
    }

    /// <summary>
    /// Gets the changes [Deleted, changed, inserted] comparing this collection to another.
    /// </summary>
    /// <param name="local">The source collection.</param>
    /// <param name="remote">The remote collection to comare agains.</param>
    /// <param name="keySelector">The primary key selector function</param>
    /// <param name="compareFunc">Optional camparing function between 2 objects of type TSource</param>
    /// <returns>List of changes as Added, Removed and Changed items of type TSource</returns>
    public static ChangeResult<TLocal, TLocal> CompareToImpl4<TLocal, TKey>(
         IEnumerable<TLocal> local, IEnumerable<TLocal> remote, Func<TLocal, TKey> keySelector, Func<TLocal, TLocal, bool> compareFunc = null)
    {
        if (local == null)
            throw new ArgumentNullException("local");
        if (remote == null)
            throw new ArgumentNullException("remote");
        if (keySelector == null)
            throw new ArgumentNullException("keySelector");

        var remoteKeyValues = remote.ToDictionary(keySelector);
        var localKeyValues = local.ToDictionary(keySelector);
        var changed = new List<Tuple<TLocal, TLocal>>();

        foreach (var localItem in local)
        {
            var localItemKey = keySelector(localItem);

            //1. Check if item is both in local and remote
            Dictionary<TLocal, TLocal> remoteItemValue;
            if (remoteKeyValues.Remove(localItemKey, out  remoteItemValue))
            {
                //1.a item is in both collections -> check if they are different
                var isItemChanged = compareFunc != null ? !compareFunc(localItem, remoteItemValue) :
                 !localItem.Equals(remoteItemValue);

                if (isItemChanged)
                {
                    //1.b are different -> mark a change
                    changed.Add(new Tuple<TLocal, TLocal>(localItem, remoteItemValue));
                }

                //1.c remove the item from local list as it's prensent in remote list too
                //this should never return false
                localKeyValues.Remove(localItemKey, out var localItemValue);
            }

            //2. if item is not in remote list means it has been removed
        }

        var deleted = localKeyValues.Values;
        var inserted = remoteKeyValues.Values;

        return new ChangeResult<TLocal, TLocal>(deleted, changed, inserted);
    }
}

class User
{
    public string Key { get; set; }

    public string Name { get; set; }
}

static class Utils
{
    public static Random random = new Random();
    public static string RandomString(int length)
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        return new string(Enumerable.Repeat(chars, length)
          .Select(s => s[random.Next(s.Length)]).ToArray());
    }
}

[CoreJob]
[RankColumn]
public class ListChangeDetection
{
    private List<User> _localItems;
    private List<User> _remoteItems;

    [Params(1000, 100000)]
    public int N;

    [GlobalSetup]
    public void Setup()
    {
        _localItems = Enumerable.Range(1, N).Select(_ => new User() { Key = "User" + _, Name = Utils.RandomString(10) }).ToList();
        _remoteItems = _localItems.ToList();
        _remoteItems.RemoveRange(Utils.random.Next(10, N / 5), Utils.random.Next(N / 5));
        var startChangeIndex = Utils.random.Next(10, N);
        for (int i = startChangeIndex; i < Math.Min(Utils.random.Next(100, N / 5), N - startChangeIndex); i++)
            _remoteItems[i].Name = Utils.RandomString(10);
    }

    [Benchmark]
    public void Impl1() => ListExtensions.CompareToImpl1(_localItems, _remoteItems, _ => _.Key);

    [Benchmark]
    public void Impl2() => ListExtensions.CompareToImpl2(_localItems, _remoteItems, _ => _.Key);

    [Benchmark]
    public void Impl3() => ListExtensions.CompareToImpl3(_localItems, _remoteItems, _ => _.Key);

    [Benchmark]
    public void Impl4() => ListExtensions.CompareToImpl4(_localItems, _remoteItems, _ => _.Key);

}

BenchmarkRunner.Run<ListChangeDetection>();