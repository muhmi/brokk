# Brokk

**TODO: Add description**


brain
	- separate interface for storing information
	- should support ETS/DETS/Redis?
	- key/value db is enough?

worker
	- a gen server that orchestrates everything

plugins
	- integrations to some service that sends events to
	  worker and possiby receives events to

	- flowdock integration

	- jenkins integration

	- aws integration

	- plugins that react to chat messages

other

	- should have a file watcher to automatically compile & load plugins
	  for easy local development

	- should provide easy audit of what the bot has been up to

	- easy aws / heroku setup

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add brokk to your list of dependencies in `mix.exs`:

        def deps do
          [{:brokk, "~> 0.0.1"}]
        end

  2. Ensure brokk is started before your application:

        def application do
          [applications: [:brokk]]
        end

