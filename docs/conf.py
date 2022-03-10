# -*- coding: utf-8 -*-
# This is needed for docs build, it's here so we can use docs in modules
import os
import sys
import shutil
import subprocess
from pkg_resources import require

require("sphinx_rtd_theme")
require("matplotlib")

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, ROOT)

# Get the git version
#git_version = subprocess.check_output(
#    "git describe --abbrev=7 --dirty --always --tags".split(), text=True)


# Copy across the module rst files into the build dir
def setup(app):
    build_dir = os.path.join(ROOT, "docs", "build")
    if os.path.isdir(build_dir):
        shutil.rmtree(build_dir)
    os.mkdir(build_dir)
    files = []
    modules_root = os.path.join(ROOT, "modules")
    for module_name in sorted(os.listdir(modules_root)):
        module_root = os.path.join(modules_root, module_name)
        for f in sorted(os.listdir(module_root)):
            if f.endswith("_doc.rst"):
                shutil.copy(os.path.join(module_root, f), build_dir)
                files.append(os.path.join("build", f[:-4]))
    target_modules_root = os.path.join(ROOT, "targets", "PandABox", "blocks")
    #for module_name in sorted(os.listdir(target_modules_root)):
    #    target_module_root = os.path.join(target_modules_root, module_name)
    #    for f in sorted(os.listdir(target_module_root)):
    #        if f.endswith("_doc.rst"):
    #            shutil.copy(os.path.join(target_module_root, f), build_dir)
    #            files.append(os.path.join("build", f[:-4]))
    with open(os.path.join(build_dir, "blocks.txt"), "w") as f:
        f.write("""
.. toctree::
    :maxdepth: 1

    %s
""" % ("\n    ".join(files),))


# -- General configuration ------------------------------------------------
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.intersphinx',
    'sphinx.ext.viewcode',
    'sphinx.ext.graphviz',  # Required for digraph in pcomp doc
    'matplotlib.sphinxext.plot_directive',
    'common.python.sphinx_timing_directive',
    'common.python.sphinx_block_fields_directive',
]

try:
    import sphinxcontrib.napoleon
except ImportError:
    extensions.append('sphinx.ext.napoleon')
else:
    extensions.append('sphinxcontrib.napoleon')

autoclass_content = "both"

autodoc_member_order = 'bysource'

graphviz_output_format = "svg"

# If true, Sphinx will warn about all references where the target can't be found
nitpicky = True

# The name of a reST role (builtin or Sphinx extension) to use as the default
# role, that is, for text marked up `like this`
default_role = "any"

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix of source filenames.
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'PandABlocks-FPGA'
copyright = u'2015, Diamond Light Source'
author = u'Tom Cobb'

# The full version, including alpha/beta/rc tags.
release = subprocess.check_output([
    'git', 'describe', '--abbrev=7', '--dirty','--always', '--tags'])
release = release.decode()
# The short X.Y version.
version = ".".join(release.split(".")[:2])

exclude_patterns = ['_build']

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

intersphinx_mapping = {
    "python": (
        'https://docs.python.org/2.7/', None),
    "server": (
        'http://PandABlocks-server.readthedocs.io/en/latest/', None)
}

# A dictionary of graphviz graph attributes for inheritance diagrams.
inheritance_graph_attrs = dict(rankdir="TB")

# -- Options for HTML output ----------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
try:
    import sphinx_rtd_theme
    html_theme = 'sphinx_rtd_theme'
except ImportError:
    html_theme = 'default'
    print('sphinx_rtd_theme not found, using default')

# Options for the sphinx rtd theme, use black
html_theme_options = dict(style_nav_header_background="black")

# Add some CSS classes for columns and other tweaks in a custom css file
html_css_files = ["theme_overrides.css"]

# Add any paths that contain custom themes here, relative to this directory.
#html_theme_path = []

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Custom sidebar templates, maps document names to template names.
#html_sidebars = {}

# Additional templates that should be rendered to pages, maps page names to
# template names.
#html_additional_pages = {}

# If true, "Created using Sphinx" is shown in the HTML footer. Default is True.
html_show_sphinx = False

# If true, "(C) Copyright ..." is shown in the HTML footer. Default is True.
html_show_copyright = True

# Output file base name for HTML help builder.
htmlhelp_basename = 'PandABlocks-FPGAdoc'

# Logo
html_logo = 'PandA-logo-for-black-background.svg'
html_favicon = 'PandA-logo.ico'


# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #'papersize': 'letterpaper',

    # The font size ('10pt', '11pt' or '12pt').
    #'pointsize': '10pt',

    # Additional stuff for the LaTeX preamble.
    #'preamble': '',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    ('contents', 'PandABlocks-FPGA.tex', u'PandABlocks-FPGA Documentation',
     u'Tom Cobb', 'manual'),
]

# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    ('contents', 'PandABlocks-FPGA', u'PandABlocks-FPGA Documentation',
     [u'Tom Cobb'], 1)
]

# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    ('contents', 'PandABlocks-FPGA', u'PandABlocks-FPGA Documentation',
     u'Tom Cobb', 'PandABlocks-FPGA', 'A short description',
     'Miscellaneous'),
]

# Common links that should be available on every page
rst_epilog = """"""
