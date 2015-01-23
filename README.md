# Buildpack for Clojure [![Build Status](https://travis-ci.org/cloudControl/buildpack-clojure.svg?branch=master)](https://travis-ci.org/cloudControl/buildpack-clojure)

This is a [buildpack](https://www.cloudcontrol.com/dev-center/Platform%20Documentation#buildpacks-and-the-procfile) for
Clojure apps, powered by [Leiningen](http://leiningen.org).

## Usage
This is our default buildpack for Clojure applications. In case you want to introduce some changes, fork our buildpack,
apply changes and test it via [custom buildpack feature](https://www.cloudcontrol.com/dev-center/Guides/Third-Party%20Buildpacks/Third-Party%20Buildpacks):

    $ cctrlapp APP_NAME create custom --buildpack https://github.com/cloudControl/buildpack-clojure.git

The buildpack will use Leiningen to install your dependencies.

Example usage for an app already stored in git:

    $ tree
    |-- Procfile
    |-- project.clj
    |-- README.md
    |-- resources
        `-- public
            `__ ...
    `-- src
        `-- sample
            `-- app.clj

    $ cctrlapp APP_NAME create java

    $ cctrlapp APP_NAME push
    [...]
    -----> Receiving push
    -----> Installing OpenJDK 1.7...-----> Installing OpenJDK 1.7(openjdk7.b32.tar.gz)... done
    done
    -----> Installing Leiningen
           Downloading: leiningen-2.4.2-standalone.jar
           Writing: lein script
    -----> Building with Leiningen
           Running: lein with-profile production compile :all
           (Retrieving org/clojure/clojure/1.6.0/clojure-1.6.0.pom from central)
           [...]
           Compiling app
    -----> Building image
    -----> Uploading image (59M)

    To ssh://APP_NAME@cloudcontrolled.com/repository.git
     * [new branch]      master -> master

The buildpack will detect your app as Clojure if it has a
`project.clj` file in the root. If you use the
[clojure-maven-plugin](https://github.com/talios/clojure-maven-plugin),
[the standard Java buildpack](https://github.com/cloudControl/buildpack-java)
should work instead.

## Configuration

Leiningen 1.7.1 will be used by default, but if you have
`:min-lein-version "2.0.0"` in project.clj (highly recommended) then
the latest Leiningen 2.x release will be used instead.

Your `Procfile` should declare what process types which make up your
app. Often in development Leiningen projects are launched using `lein
run -m my.project.namespace`, but this is not recommended in
production because it leaves Leiningen running in addition to your
project's process. It also uses profiles that are intended for
development, which can let test libraries and test configuration sneak
into production.

### Uberjar

If your `project.clj` contains an `:uberjar-name` setting, then
`lein uberjar` will run during deploys. If you do this, your `Procfile`
entries should consist of just `java` invocations.

If your main namespace doesn't have a `:gen-class` then you can use
`clojure.main` as your entry point and indicate your app's main
namespace using the `-m` argument in your `Procfile`:

    web: java $JVM_OPTS -cp target/myproject-standalone.jar clojure.main -m myproject.web

If you have custom settings you would like to only apply during build,
you can place them in an `:uberjar` profile. This can be useful to use
AOT-compiled classes in production but not during development where
they can cause reloading issues:

```clj
  :profiles {:uberjar {:main myproject.web, :aot :all}}
```

If you need Leiningen in a `cctrlapp run` session, it will be downloaded on-demand.

Note that if you use Leiningen features which affect runtime like
`:jvm-opts`, extraction of native dependencies, or `:java-agents`,
then you'll need to do a little extra work to ensure your Procfile's
`java` invocation includes these things. In these cases it might be
simpler to use Leiningen at runtime instead.

### Leiningen at Runtime

Instead of putting a direct `java` invocation into your Procfile, you
can have Leiningen handle launching your app. If you do this, be sure
to use the `trampoline` and `with-profile` tasks. Trampolining will
cause Leiningen to calculate the classpath and code to run for your
project, then exit and execute your project's JVM, while
`with-profile` will omit development profiles:

    web: lein with-profile production trampoline run -m myapp.web

Including Leiningen in your slug will add about ten megabytes to its
size and will add a second or two of overhead to your app's boot time.

### Overriding build behavior

If neither of these options get you quite what you need, you can check
in your own executable `bin/build` script into your app's repo and it
will be run instead of `compile` or `uberjar` after setting up Leiningen.

## JDK Version

By default you will get OpenJDK 1.6. To use a different version, you
can commit a `system.properties` file to your app.

```
$ echo "java.runtime.version=1.7" > system.properties
$ git add system.properties
$ git commit -m "JDK 7"
```

## Troubleshooting

To see what the buildpack has produced, do `cctrlapp APP_NAME run bash` and you
will be logged into an environment with your compiled app available.
From there you can explore the filesystem and run `lein` commands.
