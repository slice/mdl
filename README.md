# mdl

mdl is a Python 3.6 library and script aimed at making downloading things from
Curseforge easier and intuitive.

## Installing

Python 3.6+ required.

```sh
$ pip3 install 'git+https://github.com/slice/mdl.git'
```

### Dependencies

Installed by `pip` automatically:

* `requests`
* `beautifulsoup4`

## Usage

```py
>>> from mdl.curse import search
>>> results = search('Tinkers Construct')
>>> results
[
  <Project name="Construct's Armory" slug='constructs-armory' owner='TheIllusiveC4'>,
  <Project name='Tinkers Survival' ...>,
]
>>> next(project for project in results if project.name == 'Tinkers Construct')
<Project name='Tinkers Construct' slug='tinkers-construct' owner='mDiyo'>
>>> tinkers_construct = _
>>> tinkers_construct.files()
[
  <File name='TConstruct-1.12.2-2.10.1.87.jar' link='https://...'>,
  <File name='TConstruct-1.12.2-2.10.1.84.jar' ...>,
]
```
