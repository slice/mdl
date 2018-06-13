import setuptools

from mdl import __version__

with open('README.md', 'r') as fh:
    long_description = fh.read()

setuptools.setup(
    name="mdl",
    version=__version__,
    author="slice",
    author_email="ryaneft@gmail.com",
    description="A Curseforge scraper library",
    install_requires=['requests', 'beautifulsoup4'],
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/slice/mdl",
    packages=setuptools.find_packages(),
    python_requires='~=3.6',
    classifiers=(
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3 :: Only',
        'Natural Language :: English',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ),
)
