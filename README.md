# rb3-image-scripts
Summer 2024 Intern Project: Build scripts to create Qualcomm RB3 prebuilt proprietary binaries and images as both a Qualcomm unregistered and registered user that can be flashed and booted to the device

Script workflow sourced from https://docs.qualcomm.com/bundle/publicresource/topics/80-70014-254/github_workflow_unregistered_users.html?product=1601111740013072

Some changes may need to be made to ~/.gitconfig to replace faulty links, especially for the URLs starting with git:// or have /git/ in their paths. The provided .gitconfig file can be used as a reference. The registered user scripts require the user to sign in to their Qualcomm account to access the resources. The builds, especially the successful ones, may take a while to finish because of the bitbake command. 
