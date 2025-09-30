# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.1.0] - 03-08-2023

- Changed foreach(){} to ForEach-Object {}
Changed foreach(){} to ForEach-Object {} to limit the memory usage. In the overall duration of the script this will be a bit slower/less similar.
And the start-sleep after each action is changed from 10 milliseconds to 20 milliseconds. This is because there are max/ 50 calls per second (1 sec / 50 = 20 milliseconds).
In theory, due to the reduced memory usage, it should now be able to run on the Cloud agent as well.
Furthermore, some extra logging is added so that we know exactly where (which person (student) and which contract (education)) the error occurs when the import fails.

### Deprecated

### Removed
