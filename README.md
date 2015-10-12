[![Build Status](https://snap-ci.com/haciendaio/hacienda/branch/master/build_image)](https://snap-ci.com/haciendaio/hacienda/branch/master)
# Hacienda
Hacienda is a small RESTful service built to manage content and its translations stored as JSON

# How does it work?
Hacienda has 3 main characteristics:
  1. Content as JSON
  2. RESTful interface 
  3. Usage of Git and GitHub as storage

It categorizes the content as being either in draft or public state. It also handles translations.

## Content as JSON ##
All the content stored and managed by Hacienda is in JSON format. The service expects to receive the content as JSON and it will be returned as JSON. By using JSON for storage, Hacienda enforces separation between content and presentation. It's important to make the distinction to allow the same content being presented or styled in different ways. Also, styling and presentation of content are separate concerns than storing and managing it.

## RESTful interface ##
Hacienda is built as a separate service (much like in a microservice architecture) hence a way to interact with it via http was needed. The approach taken was to consider each item as a resource and use the RESTful way to access and manage it. A short mapping can be found below:
  * Retrieving - GET /:type/:id, Accept-Language: :locale
  * Creating - POST /:type/:locale
  * Publishing - PUT /:type/:id/:locale
  * Deleting - DELETE /:type/:id/:locale
See below the how the translation and publishing works

## Git and GitHub for storage ##
The JSON content is stored in files on the filesystem backed in a git local repo. This makes the retrieving very fast as the folder structure is mapped directly to the url structure. All reads are done from the local repo. A GitHub repository is used to achieve consistency across multiple nodes. All actions that change state (writing, publishing, deleting) are done via the GitHub API on the GitHub repo. Hacienda nodes are registered with the GitHub repo via a webhook which fires an update of the local repo every time the GitHub repo is modified.

## Draft / Public states ##
An item that was created but not published has only a draft state. If one version of the item was published, the item has a public state. The only difference between an item version being in draft or public state is accessibility. More precisely, a public version can be read (though not modified) without authentication while a version in draft state cannot be read or modified without authentication. It should be noted that only the current version of the item in draft state can be published, but the draft item can be modified without affecting the public version. This means that it can be possible for the draft and public versions of an item to be different.

## Authentication ##
Hacienda uses [HMAC authentication](https://en.wikipedia.org/wiki/Hash-based_message_authentication_code) to enable access for modifying items. A consumer has to be given a secret and an id that are shared with Hacienda instance. The consumer needs to pass a hash of the content along with its id. For more information look at the [curl wrapper](https://github.com/www-thoughtworks-com/hacienda/blob/master/scripts/curl.rb) built for testing.

## Translations ##
A resource for Hacienda is an item translated in a language. Considering the case where we have blog posts as a type of content, then the English translation of a certain blog post is a resource. The only thing that links different translations of the same item is their id.

Retrieving of an item means asking for the item's translation in a language. This means that translation rules are applied and one of the item's translations is returned. The translation rules are the following:
  1. If the item is translated in the language that is asked for, that translation is returned.
  2. If rule 1 does not apply and the item has an English translation, the English translation is returned.
  3. If rules 1 and 2 dont apply, the translation first created is returned.

# How to get started #
Hacienda is written in Ruby and uses Sinatra to serve its API. It is distributed as a Ruby gem. A good example of how to use Hacienda is in [config.ru](https://github.com/www-thoughtworks-com/hacienda/blob/master/config.ru) file. To get started you would need to provide 2 values:
  1. config file with GitHub username and GitHub repo name
  2. GitHub OAuth Token as environment value

An example of a config file can be found [here](https://github.com/www-thoughtworks-com/hacienda/blob/master/config/config.example.yml). The "GitHub username" and "GitHub repo" should be replaced with the GitHub repo you want to use and the GitHub username under which the repo is created. You can run the bootstrap:config rake task and type in the values for the user and repo. You can provide a nonexistent repo, as the task will create a repo for you.

The GitHub OAuth Token gives write and read access to the repo. Read [here](https://developer.github.com/v3/oauth/) about how it works. In order to generate one, follow [these](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) instructions from GitHub. Once you have it, set a environment variable called GITHUB_OAUTH_TOKEN with its value.

To test the server is working you need to:
  1. Create a consumer id and secret using bootstrap:generate_id_and_secret task
  2. Add the consumer id and secret just created to Hacienda using bootstrap:add_consumer_with_credentials task
  3. Use the [curl wrapper](https://github.com/www-thoughtworks-com/hacienda/blob/master/scripts/curl.rb) to make HTTP calls. The wrapper adds the authentication headers needed using the a consumer id and secret provided. 
  
Synchronization between the local repo and the GitHub one can be done manually by making a POST to /content-updated endpoint. When deploying use bootstrap:webhook to setup a webhook in GitHub that will be triggered when anything in the GitHub repo changes.

## Developer notes ##
The requirements for Hacienda are Ruby and a couple of pre-requisites for the gems used. Take a look at [vagrant_setup.sh](https://github.com/www-thoughtworks-com/hacienda/blob/master/vagrant_setup.sh) script that's used to provision the Vagrant box provided. Use the steps described below to use the Vagrant box as a guideline for setup - this assumes minimal knowledge of Vagrant:
  1. Run TOKEN="Github OAuth Token" vagrant up - see [here](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) how to generate a GitHub OAuth token
  2. SSH into the vagrant box and go to the /vagrant folder 
  3. Run bundle install - make sure all the gems are installed correctly
  4. Run bundle exec rake bootstrap:config and pass a the GitHub username and repo name used
  5. Run bundle exec rake run and Hacienda should be running
