# Codacy Example Tool [![Codacy Badge](https://api.codacy.com/project/badge/Grade/7622fdf861c34d69971a8b04aca65fef)](https://www.codacy.com/gh/codacy/codacy-example-tool?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=codacy/codacy-example-tool&amp;utm_campaign=Badge_Grade) [![Build Status](https://circleci.com/gh/codacy/codacy-example-tool.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/codacy/codacy-example-tool)

Docker engine example for a Codacy tool.

This repository is an example of a tool and has the instructions to develop and 
test a [Codacy Tool](#what-is-a-codacy-tool).

## Documentation

### What is a Codacy tool

A Codacy Tool is a Docker-based container that wraps linters or tools, ingesting 
their result and outputting a standardised json document that can be ingested by 
Codacy. 
The accepted output format can be found at [Output format](#output-format) section.

As input the tool accepts a configuration file, [.codacyrc](#structure).

### How to integrate an external analysis tool on Codacy

By creating a docker and writing code to handle the tool invocation and output,
you can integrate the tool of your choice on Codacy!

> To know more about dockers, and how to write a docker file please refer to
> [https://docs.docker.com/reference/builder/](https://docs.docker.com/reference/builder/)

You can check the code of an already implemented tool and, if you wish, fork it
to start your own. You are free to modify and use it for your own tools.

#### Structure

* In order to run the tool, it's necessary to include a configuration file 
[`/.codacyrc`](#structure-of-the-codacyrc-file), containing information about the language and potential additional parameters.
* The source code to be analysed will be located in `/src`, meaning that when
  provided in the configuration, the file paths are relative to `/src`.

##### Structure of the .codacyrc file

This file has:

* **files:** Files to be analysed (their path is relative to `/src`)
* **tools:** Array of tools
  * **name:** Unique identifier of the tool. This will be provided by the tool
    in patterns.json file.
  * **patterns:** Array of patterns that must be checked
    * **patternId:** Unique identifier of the pattern
    * **parameters:** Parameters of the pattern
      * **name:** Unique identifier of the parameter
      * **value:** Value to be used as parameter value

```json
{
  "files" : ["foo/bar/baz.js", "foo2/bar/baz.php"],
  "tools":[
    {
      "name":"jshint",
      "patterns":[
        {
          "patternId":"latedef",
          "parameters":[
            {
              "name":"latedef",
              "value":"vars"
            }
          ]
        }
      ]
    }
  ]
}
```

##### Behavior of the configuration file 

The tool parses the configuration file provided and uses it to define its own behaviour. 
This configuration file is the way to specify which source files to analyse and 
which patterns to include in that analysis.

Depending on the configuration, the tool should have different behaviours for
the following situations:

* If `/.codacyrc` exists:

  * Files defined -> run tool on the source files passed (an empty array is still defined).

  * Files undefined -> run tool for all source files inside `/src`.

  * Patterns defined -> run tool with the defined patterns (an empty array is still defined).

  * Patterns undefined -> run tool with the native configuration file if present, otherwise use the tool default patterns.

* If `/.codacyrc` does not exist, run the tool for all source files on `/src` using the tool's native configuration or with the default patterns (if native configuration does not exist).

* If `/.codacyrc` fails to be parsed, throw an error.

##### General tool behavior

**Exit codes**:

* The exit codes are different, depending on the tool invocation is successful or not:
  * **0**: The tool executed successfully :tada:
  * **1**: An unknown error occurred while running the tool :cold_sweat:
  * **2**: Execution timeout :alarm_clock:

**Environment variables**:

* To run the tool in debug mode, so you can have more detailed logs, you need to
  set the environment variable `DEBUG` to `true` when invoking the docker.
* To configure a different timeout for the tool, you have to set the environment
  variable `TIMEOUT_SECONDS` when you run the docker image, setting it with values
  like `10` or `1800` (30 minutes).

#### Output format

After you have your results from the tool, you should print them 
to the standard output, one per line:

- filename: file where the issue was found
- message: issue message returned by the linter
- patternId: pattern the issue corresponds to
- line: line where the issue was found

```
{
    "filename":"codacy/core/test.js",
    "message":"found this in your code",
    "patternId":"latedef",
    "line":2
}
```

> The filename should not be the absolute path (not include the `/src/`)
> `/src/codacy/core/test.js` should be returned as `codacy/core/test.js`

#### Setup

##### Requirements

* [Docker](https://docs.docker.com/v17.09/engine/installation/)

1. Write the docker file that will run the tool.
    * It must have a binary entry point without any parameters.

2. Write a patterns.json ([schema](schemas/patterns_json_schema.json)) with the configuration of your tool.
    * This file must be located on /docs/patterns.json.
      * **name:** Unique identifier of the tool (lower-case letters without
        spaces)
      * **version:** Tool version to display in the Codacy UI
      * **patterns:** The patterns that the tool provides
          * **patternId:** Unique identifier of the pattern (lower-case letters
            without spaces)
          * **level:** Severity level of the issue
          * **category:** Category of the issue
          * **parameters:** Parameters received by the pattern
            * **name:** Unique identifier of the parameter (lower-case letters
              without spaces)
            * **default:** Default value of the parameter. 
              **The tool must ensure the default value is used when it is not sent on the configuration file.**

    ```json
    {
        "name":"jshint",
        "version": "1.2.3",
        "patterns":[
        {
            "patternId": "latedef",
            "category": "ErrorProne",
            "parameters": [
            {
                "name": "latedef",
                "default": "nofunc"
            }
            ],
            "level": "Warning"
        }
        ]
    }
    ```

3. Write the code to run the tool

  You can write the code in any language you want but, you have to invoke the
  tool according to the configuration. After you have your results from the
  tool, you should print them to the standard output in our Result format ([schema](schemas/output_schema.json)), one
  result per line.

* The filename should **not** include the prefix "/src/". Example:
  * absolute path: /src/folder/file.js
  * filename path: folder/file.js

  ```json
  {
      "filename":"codacy/core/test.js",
      "message":"found this in your code",
      "patternId":"latedef",
      "line":2
  }
  ```

* If you are not able to run the analysis for any of the files requested you
  should return an error for each one of them to the standard output in our
  Error format.

   ```json
   {
     "filename":"codacy/core/test.js",
     "message":"could not parse the file"
   }
   ```

* When an unknown error occurred while running the tool, it should send the
  error information through the standard error and exit with error code 1. See
  exit codes section.

#### Tool Documentation

At Codacy we strive to provide the best value to our users and, to accomplish
that, we document our patterns so that the user can better understand the
problem and fix it.

At this point, your tool has everything it needs to run, but there is one other
really important thing that you should do before submitting your docker: the
documentation for your tool.

Your files for this section should be placed in /docs/description/.

In order to provide more details you can create:

* A single /docs/description/description.json file.
* A /docs/description/`<PATTERN-ID>.md` file for each pattern.

##### Levels and Categories

For level types we have:

* Error - High priority issues. These issues show the code that is very susceptible to problems.
* Warning - You should be careful abou these issues as they are based on code standards and conventions.
* Info - The least critical issue type.

For category types we have:

* ErrorProne - Code that may hide bugs.
* CodeStyle - Code formatting and syntax problems.
* Complexity - Code that is highly complex and that should be refactored.
* UnusedCode - Code that is never used
* Security - Code that may have security issues
* Compatibility - Compatibility problems across different versions (mainly for frontend code)
* Performance - Code that has performance problems
* Documentation - Methods and classes that do not have the correct comment annotations
* BestPractice

##### Description structure

The documentation description is optional but must be added as much as possible.

In the `description.json` ([schema](schemas/description_json_schema.json)) you define the title for the pattern, brief description,
time to fix (in minutes), and also a description of the parameters in the
following format:

```json
[
  {
    "patternId": "latedef",
    "title": "Enforce variable def before use",
    "description": "Prohibits the use of a variable before it was defined.",
    "parameters": [
      {
        "name": "latedef",
        "description": "Declaration order verification. Check all [true] | Do not check functions [nofunc]"
      }
    ],
    "timeToFix": 10
  }
]
```

To give a more detailed explanation about the issue, you should define the
`<PATTERN-ID>.md`. Example:

```markdown
Fields in interfaces are automatically public static final, and methods are
public abstract.
Classes or interfaces nested in an interface are automatically public and static
(all nested interfaces are automatically static).

For historical reasons, modifiers which are implied by the context are accepted
by the compiler, but are superfluous.

Ex:

    public interface Foo {
        public abstract void bar();         // both abstract and public are ignored by the compiler
        public static final int X = 0;         // public, static, and final all ignored
        public static class Bar {}             // public, static ignored
        public static interface Baz {}         // ditto

        void foo();                            //this is correct
    }

    public class Bar {
        public static interface Baz {} // static ignored
    }

[Source](http://pmd.sourceforge.net/pmd-5.3.2/pmd-java/rules/java/unusedcode.html#UnusedModifier)
```

You should explain the what and why of the issue. Adding an example is always a
nice way to help other people understand the problem. For a more thorough
explanation you can also add a link at the end referring a more complete source.

**Notes:**

* Documentation Generator: This documentation should also be generated
  automatically to avoid having to go through all of the files each time it
  needs to be updated.

#### Test

Follow the instructions at
[codacy-plugins-test](https://github.com/codacy/codacy-plugins-test/blob/master/README.md#test-definition).

#### Submit the docker

**Running the docker**:

```bash
docker run -t \
--net=none \
--privileged=false \
--cap-drop=ALL \
--user=docker \
--rm=true \
-v <PATH-TO-FOLDER-WITH-FILES-TO-CHECK>:/src:ro \
<YOUR-DOCKER-NAME>:<YOUR-DOCKER-VERSION>
```

**Docker restrictions**:

* Docker image size should not exceed 500MB
* Docker should contain a non-root user named docker with UID/GID 2004, associated with a docker group
* All the source code of the docker must be public
* The docker base must officially be supported on DockerHub
* Your docker must be provided in a repository through a public git host (ex:
  GitHub, Bitbucket, ...)

**Docker submission**:

* To submit the docker you should send an email to support@codacy.com with the
  link to the git repository with your docker definition.
* The docker will then be subjected to a review by our team and we will then
  contact you with more details.

If you have any question or suggestion regarding this guide please contact us at
support@codacy.com.

## What is Codacy

[Codacy](https://www.codacy.com/) is an Automated Code Review Tool that monitors
your technical debt, helps you improve your code quality, teaches best practices
to your developers, and helps you save time in Code Reviews.

### Among Codacy’s features

* Identify new Static Analysis issues
* Commit and Pull Request Analysis with GitHub, BitBucket/Stash, GitLab (and
  also direct git repositories)
* Auto-comments on Commits and Pull Requests
* Integrations with Slack, HipChat, Jira, YouTrack
* Track issues in Code Style, Security, Error Proneness, Performance, Unused
  Code and other categories

Codacy also helps keep track of Code Coverage, Code Duplication, and Code
Complexity.

Codacy supports PHP, Python, Ruby, Java, JavaScript, and Scala, among others.

### Free for Open Source

Codacy is free for Open Source projects.
