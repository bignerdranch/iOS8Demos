##Interactive Playgrounds

WWDC 2014 was full of surprises and exciting technology to explore.  The new `Playground` was high on that list.  `Playgrounds` provide a convenient environment to rapidly develop and try out code.  Apple's [`Ballons.playground`](https://developer.apple.com/swift/blog/?id=9) demonstrates much of the power of the `Playground`: it can serve as both a document and as a REPL.  The combination of the two means that a `Playground` is a fully interactive document.

Given that `Playgrounds` are highly interactive, they are a wonderful vehicle for distributing code samples with instructive documentation.  They can furthermore be used as an alternative medium for presentations.  Consider a typical presentation: the presenter is giving a talk using whatever software she or he prefers, and then it is time to show off some code.  Or, perhaps the presenter was asked a question that requires experimentation.  In either scenario, the presentation is deferred momentarily in favor of Xcode.  While this process is somewhat effective, it disturbs the flow of the presentation.  `Playgrounds` provide us with a mechanism to experiment with and demonstrate code without ever leaving the presentation.

In this post, I will show you how to peek inside the `.playground` file to gain a sense of how a `Playground` is put together.  Glancing at these internals will help you to create your own interactive document.  At the end of this post, you will have created your own `Playground` featuring text and external resources, all the while taking advantage of the `Playground's` REPL.

###A Peek Inside

Let's begin by downloading Apple's `Balloons.playground`.  Go ahead and click on the link above.  One you have it downloaded, move the file somewhere convenient.

Now that you have the file, right-click on the `Balloons.playground` file and select "Show Package Contents".  Doing so will reveal a number of files.  Interestingly, what appeared to be a single file is actually made up of several others.  It is this hidden organization that drives some of the subtle power delivered by a `Playground`.  You should see something like the image below.

![Playground Package Contents](playgroundPackageContents.png)

Notice that you have three types of files, and two directions.  For files, you have: 1) `contents.xcplayground`, 2) a number of `.swift` files, and 3) a `timeline.xctimeline`.  The first is a sort of manifest file that tells the `Playground` how to display and organize its content; I will discuss this file in greater detail in the next section.  The second set of file types contain the actual Swift code that is executed in the `Playground`.  Last, the third sort of file describes the timeline feature displayed in the Assistant Editor.

For directories, the `Balloons.playground` file has "Documentation" and "Resources".  Clicking on this first folder reveals that it contains a number of `.html` files and one `.css` file.  The lesson to be learned here is that the "Documentation" folder holds all of the textual content of the `Playground` described as a series of web pages.  The CSS file defines the `Playground's` styling of these pages.  Finally, the "Resources" folder contains all of the external assets that the `Playground` uses to render the game's content.

Now that you have seen the hidden secrets of the Swift `Playground`, let's make our own interactive document!

###An Interactive Presentation

As mentioned above, imagine that you are teaching a class on Swift.  You would like to make a presentation on constants and variables, and would prefer that your presentation takes advantage of the Swift REPL.  Good news!  You can make your presentation right inside of Swift.

Create a new `Playground` called `Interactive.playground`.  Save this file where you like.  Next, right-click on `Interactive.playground` and select "Show Package Contents".  You will see two files of note: 1) `contents.xcplayground`, and 2) `section-1.swift`.  Go ahead and open `contents.xcplayground` in your text editor of choice.  You should see something similar to the image below.

![Contents](contentsPlayground.png)

As you can see, this is an XML file that acts as a manifest for the `Playground`: it describes the organization of the `Playgrounds`'s content.  You will put your content inside the `sections` tag.  Notice the `code` tag?  This tag links to a file in the `Playground` that contains your Swift code.  If you open the `section-1.swift` file, you should see the standard `Playground` boilerplate code:

```
import UIKit

var str = "Hello, playground"
```

Delete the contents of this file, and replace it with the following:

```
let myName = "Matt Mathias"
// try to change myName; what happens?

var myAge = 32
// try to change myAge; what happens?
```

If you open the `Playground`, then you should see that the code has changed.

####Adding Documentation

Recall that `Balloons.playground` had a directory called `Documentation`.  The directory contained a number of `.html` files, and each of these files were linked against in the XML inside the `contents.xcplayground` file.  Copy that organization by creating a new folder inside `Interactive.playground` called `Documentation`.

Now, switch to this folder and add a new file called `section0.html`.  Open this file, and add the following HTML to it.s