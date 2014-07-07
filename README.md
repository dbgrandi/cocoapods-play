# cocoapods-play

Asks politely if `PODNAME` can come out and play by creating a playground.

Release Note from Apple:

 > Playgrounds are not currently sandboxed. They run with the full permissions of the logged in user. Care should be taken before opening playgrounds obtained from others. Before opening the playground you can inspect the code in a playground by looking in `.swift` files inside the playground wrapper. Control click the playground in Finder and choose `Show Package Contents` to see the contents of that playground. (16773467)!

## What's the deal?

I want this to work, but Swift is young and there are things preventing us from using third party
code ([easily, at least](http://samdmarshall.com/blog/custom_frameworks_and_swift.html)) in
`.playground` files. File your radars.

Hopefully, as we get closer to Swift being finalized into a release, this will become a better tool. For
now, it's a hack.

## Installation

    $ gem install cocoapods-play

## Usage

    $ pod play POD_NAME || GIT_URL

Downloads the specified pod and creates a new playground that includes any swift files found in the podspec
`source_files` attribute, so you can just play in the sand making sandcastles.

## Todo

- If there is a README.playground file, we'll open that up.
- When third party import works, simplify the .playground file to not require all the code
- Handle mixed obj-c and swift based projects.
