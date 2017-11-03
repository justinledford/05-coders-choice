Name: Justin Ledford           ID:   28148527

## Proposed Project

My project will be a hash cracker, using multiple types of attacks
including dictionary, brute-force and masked attacks. It will have
a command line interface that given the hash, hash type, and
attack mode, attempt to crack the hash in parallel using
multiple processes, as well as across distributed nodes.

## Outline Structure

The application will be composed of a front-end command line interface,
and a server to receive requests from the interface. This server will
then handle the task of splitting the attack into multiple processes
and nodes. There will also be a data store to save and load computed
hashes if requested.

If time allows I will attempt to have the computation performed
using CUDA on GPU nodes, with Elixir handling the interface and server.
