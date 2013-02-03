This project should contain everything you need to build and run CVFunhouse
under Xcode 4.5.2. If you run into any problems building or running, please file
a bug.

To get started writing your own OpenCV code, try modifying the CVFPassThru
example. It contains thorough comments explaining exactly what you need to do.
Plus it starts out working, so you can easily tell if you break anything as you
hack.

NOTE: CVFunhouse includes a copy of the OpenCV library built as an iOS
framework. OpenCV is licensed separately under similar terms. See the file
"OpenCV license.txt" for details. For more information on OpenCV (including full
source code to the library), see the [OpenCV website](http://opencv.org/).

Augmented Reality
-----------------

The augmented reality demo is currently checked into a separate branch. To use
it, enter `git checkout augmented-reality` on the command line.

Rebasing
--------

If you forked or cloned before 12-Jan-2013, you'll need to rebase your code to
have your changes fit into the history properly. To do this:

* Enter `git fetch` (**Do not use** `git pull`)
* Enter `git rebase -i`
* An editor window will appear.
	* Delete the line that starts: `pick 2a02f2a`
	* Delete the line that starts: `pick 429b656`
* Save the file and close the editor.
* That's it!  You should be good to go from now on.

Sorry for the inconvenience.  This should be a one-time occurrence.