# cocoapods-play

Asks politely if `[PODNAME]` can come out and play by creating a playground.

## What's the deal?

I want this to work, but Swift is young and there are things preventing us from using third party
code (easily, at least) in `.playground` files. File your radars.

Hopefully, as we get closer to Swift being finalized into a release, this will become a better tool.

In the mean time, this is a place for messing around.

## Installation

    $ gem install cocoapods-play

## Usage

    $ pod play POD_NAME || GIT_URL

Downloads the specified pod and creates a new playground that includes any swift files found in the podspec
`source_files` attribute, so you can just play in the sand making sandcastles.

## Todo

- If there is a README.playground file, we'll open that up.
