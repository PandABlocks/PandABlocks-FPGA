# Contributing to opkg-utils


----
## Communication

Clone the **source** from the Yocto project's [git server](https://git.yoctoproject.org/opkg-utils/).

Get **help** using this repository and **discuss** changes on the [opkg mailing list](https://lists.yoctoproject.org/g/opkg).

File **bugs** and **enhancement** requests to the Yocto project's [opkg bugzilla tracker](https://bugzilla.yoctoproject.org/buglist.cgi?quicksearch=Product%3Aopkg)

Send **security** concerns directly to the project **maintainer** by email: Alex Stewart <[alex.stewart@ni.com](mailto:alex.stewart@ni.com)>

**Historic Maintainers**
- Paul Barker <paul@paulbarker.me.uk>


----
## Commit Guidelines

This project uses *commits* as the fundamental unit-of-change (not pull requests). So please follow common best practices for authoring your commits such that they are: atomic, comprehensible, and considerate of users who work in the embedded space.

**Commit Signing-offs.** Please add a sign-off to each of your commits, using the `--signoff` argument to git. (eg. `git commit -s`)

**Bug Fixes.** If your change resolves a bug from the opkg bugzilla, please include a `Closes: ${bugzilla number}` trailer to your commit message.

```bash
git commit -s --trailer Closes=12345
```


----
## Submitting Changes Upstream

**Git Send-Email.** You can submit your commits to the opkg mainline by embedding them into an email, and sending them to the opkg mailing list (<opkg@lists.yoctoproject.org>). When you do, please prefix your email with the tags: `[opkg-utils][PATCH]`.

The easiest way to do this is using the git send-email extension. You can use the following commands to configure your opkg workspace with the correct defaults.

```bash
git config diff.renames copy
git config format.to "opkg@lists.yoctoproject.org"
git config format.subjectprefix "opkg-utils][PATCH"
```

You can then create a patchset using the `git format-patch` command, and send it upstream. eg.

```bash
git format-patch origin/master..HEAD
# or
git format-patch --cover-letter origin/master..HEAD

git send-email ./*.patch
```

That should result in your patches being sent to the relevant mailing lists in the correct format. The patches should then be reviewed and you should receive feedback by email. If you haven't heard anything within 2 weeks, feel free to send us a reminder.

If you need any further help or advice, just ask on the opkg mailing list (opkg@lists.yoctoproject.org).


----
## Developer's Certificate of Origin

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
	have the right to submit it under the open source license
	indicated in the file; or

(b) The contribution is based upon previous work that, to the best
	of my knowledge, is covered under an appropriate open source
	license and I have the right under that license to submit that
	work with modifications, whether created in whole or in part
	by me, under the same open source license (unless I am
	permitted to submit under a different license), as indicated
	in the file; or

(c) The contribution was provided directly to me by some other
	person who certified (a), (b) or (c) and I have not modified
	it.

(d) I understand and agree that this project and the contribution
	are public and that a record of the contribution (including all
	personal information I submit with it, including my sign-off) is
	maintained indefinitely and may be redistributed consistent with
	this project or the open source license(s) involved.
```