from collections import namedtuple
from typing import List
from urllib.parse import urlparse, parse_qs

import requests
from bs4 import BeautifulSoup, Tag
from . import __version__

BASE_URL = 'https://minecraft.curseforge.com'
HEADERS = {
    'User-Agent': f'mdl/{__version__} requests/{requests.__version__}'
}


class Project(namedtuple('Project', 'id link slug name description owner')):
    """A Curseforge project."""

    def __str__(self):
        return f'{self.name} by {self.owner}'

    def __repr__(self):
        return (f'<Project name={self.name!r} slug={self.slug!r} '
                f'owner={self.owner!r}>')

    def files(self) -> List['File']:
        """Returns a listing of Files in this project."""
        return files(self.slug)

    @classmethod
    def _inflate(cls, element: Tag) -> 'Project':
        link = element.select('.results-name a')[0]['href']

        # parse the link to the projects page to extract some information
        url = urlparse(link)
        qs = parse_qs(url.query)

        project_id = int(qs['projectID'][0])
        slug = url.path.split('/')[2]

        return cls(
            id=project_id,
            link=BASE_URL + link,
            name=element.select('.results-name a')[0].string,
            slug=slug,
            description=element.select('.results-summary')[0].string,
            owner=element.select('.results-owner a')[0].string,
        )


class File(namedtuple('File', 'link name size uploaded mc_version downloads')):
    """A Curseforge file (inside of a project, like a mod or modpack)."""

    def __str__(self):
        return (f'{self.name} for {self.mc_version} '
                f'({self.downloads} downloads)')

    def __repr__(self):
        return f'<File name={self.name!r} link={self.link!r}>'

    @classmethod
    def _inflate(cls, element: Tag) -> 'File':
        twitch_link = element.select('.twitch-link')[0]

        maybe_download_link = \
            element.select('.project-file-download-button a.button')
        download_link = BASE_URL + maybe_download_link[0]['href'] \
            if maybe_download_link else None
        uploaded = element.select('.project-file-date-uploaded abbr')[0].string
        downloads = element.select('.project-file-downloads')[0].string.strip()

        return cls(
            link=download_link,
            name=twitch_link.string,
            size=element.select('.project-file-size')[0].string.strip(),
            uploaded=uploaded,
            mc_version=element.select('.version-label')[0].string,
            downloads=downloads,
        )


def request(endpoint: str, *args, **kwargs) -> BeautifulSoup:
    """Makes a request to the Curseforge website, relative to the root."""
    response = requests.get(BASE_URL + endpoint, *args, headers=HEADERS,
                            **kwargs)
    response.raise_for_status()
    return BeautifulSoup(response.text, 'html.parser')


def search(query: str) -> List[Project]:
    """Performs a search for projects."""
    bs = request('/search', params={'search': query})
    projects = bs.select('tr.results')
    return list(map(Project._inflate, projects))


def files(slug: str) -> List[File]:
    """Returns a listing of files for a specific mod."""
    bs = request(f'/projects/{slug}/files')
    files = bs.select('tr.project-file-list-item')
    return list(map(File._inflate, files))
