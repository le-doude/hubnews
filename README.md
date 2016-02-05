#Hubnews

##What?

This executable gem allows you to display the status of your PRs in slack.

##Why?

My team works sometimes on a lot of small tasks and creates a PR for every task. 
This PRs only get merged to our main branch once a quorum (half plus 1) of LGTMs is reached on the code.
We like it as it has saved our ass quite often, but sometimes a PR is forgotten or people are too busy. 
So I got tired of keeping on "advertising" my code on slack and ask people to give it a look and give me the LGTMs.
I created this gem so I could CRON job this tasks and remind everyone that there is some reviewing to do.

##What I assume.

I assume that LGTM comments are top level comments on a PR (aka issue comments) and that they contain the string LGTM somewhere.
Any other comment is ignored.

## Install

`git clone [this repo or a fork]`

`bundle install`

`rake install`

`rbenv rehash` if user.use_rbenv?

Someday I will bother making this a proper gem.

##Use

`hubnews setup` will generate an example file for settings

`hubnews run -f [setup file name]` will run a job

look at `hubnews -h` for understanding the commands.

##Good luck
