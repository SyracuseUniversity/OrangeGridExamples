# Sharing Files with Other Users

Home directories on the cluster are private: only you can see what is in
yours.  Nothing inside your home directory was changed to make it private,
the protection comes from the top-level directory itself, which other users
can no longer open or list.

There are two ways to let someone else read your files.

  * **For a research group that works together on an ongoing basis**, ask us
    for a shared group directory by emailing [Research
    Computing](mailto:researchcomputing@syr.edu).  Everyone in the group can
    read and write there without any of the steps below, and new members can
    be added without anyone changing permissions.

  * **To share one folder with one or two specific people**, you can grant
    them access yourself with an *access control list*, or ACL.  The rest of
    this page explains how.

The commands are the same on OrangeGrid and Zest.  Note that the two clusters
have separate home directories, so a folder shared on one is not shared on the
other.

## How access works

To read `/home/you/projects/paper/data`, another user needs two things:

  1. Permission to *pass through* every directory on the way there:
     `/home/you`, `/home/you/projects`, and `/home/you/projects/paper`.
     Passing through lets them reach the folder but not list or read anything
     else along the way.
  2. Permission to *read* the folder itself and the files in it.

ACLs are managed with two commands, `nfs4_setfacl` to change them and
`nfs4_getfacl` to look at them.  People are identified by NetID followed by
`@ad.syr.edu`.

## Sharing a folder

In this example you share `~/projects/paper/data` with the user whose NetID is
`abc123`.  First give them pass-through on each directory above the folder.
The `x` at the end of each entry means pass through only.

```bash
nfs4_setfacl -a A::abc123@ad.syr.edu:x ~
nfs4_setfacl -a A::abc123@ad.syr.edu:x ~/projects
nfs4_setfacl -a A::abc123@ad.syr.edu:x ~/projects/paper
```

Then give them read access to the folder and everything already in it

```bash
nfs4_setfacl -R -a A:fd:abc123@ad.syr.edu:rx ~/projects/paper/data
```

The `-R` applies the entry to every file and directory that is already in the
folder.  The `fd` means anything created in the folder later picks up the same
entry automatically.  `rx` lets them list directories and read files.

They can now read the files from the login nodes and from jobs running on the
cluster, using the full path

```bash
ls /home/you/projects/paper/data
```

## Checking what is shared

```bash
nfs4_getfacl ~/projects/paper/data
```

A shared folder will show a line for each person it is shared with, along with
three standard lines that every file has

```
A:fd:abc123@ad.syr.edu:rx
A::OWNER@:rwaDxtTnNcCy
A:g:GROUP@:rxtncy
A::EVERYONE@:rxtncy
```

`OWNER@`, `GROUP@` and `EVERYONE@` are the ACL form of the usual permissions
that `chmod` sets.  Running `chmod` on a shared folder does not remove the
entries you added.

Note that `ls -l` does not show whether a file has an ACL, only
`nfs4_getfacl` does.

## Letting someone write

To let someone create, change and delete files in a folder, use `rwaDx`
instead of `rx`

```bash
nfs4_setfacl -R -a A:fd:abc123@ad.syr.edu:rwaDx ~/projects/paper/data
```

Files they create there are owned by them, not by you.  If the folder is for
a group that will keep growing, a shared group directory is usually a better
fit.

## Removing access

The quickest way to stop sharing is to remove the pass-through entry on your
home directory.  Without it the other person can no longer reach anything
inside, even if entries further down are still in place

```bash
nfs4_setfacl -x A::abc123@ad.syr.edu:x ~
```

Entries must be removed exactly as `nfs4_getfacl` prints them.  To tidy up
the rest, remove the entries from the folders on the path and from the shared
folder itself.  Files created after the folder was shared carry a copy of the
entry without the `fd` flags, so remove both forms

```bash
nfs4_setfacl -x A::abc123@ad.syr.edu:x ~/projects
nfs4_setfacl -x A::abc123@ad.syr.edu:x ~/projects/paper
nfs4_setfacl -R -x A:fd:abc123@ad.syr.edu:rx ~/projects/paper/data
nfs4_setfacl -R -x A::abc123@ad.syr.edu:rx ~/projects/paper/data
```

## Things to watch out for

  * **Moving files into a shared folder does not share them.**  A file created
    in, or copied into, a shared folder picks up its entries.  A file moved in
    with `mv` keeps the permissions it had before.  Use `cp` instead, or run
    the `nfs4_setfacl -R -a` command again after moving files in.

  * **Every directory on the path needs a pass-through entry.**  If the other
    person gets `Permission denied`, check each directory between your home
    directory and the shared folder with `nfs4_getfacl`.

  * **Don't open up your whole home directory.**  Changing your home directory
    to `755` or `711` lets every user on the cluster read everything in it,
    not just the person you meant to share with.  Use the steps above instead.

  * **Changes may take up to a minute to appear** on other nodes.

## Need Help?

If you have any trouble sharing files, or would like a shared group directory,
email [Research Computing](mailto:researchcomputing@syr.edu).
