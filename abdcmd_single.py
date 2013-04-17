"""Command to process a single repository."""

import time

import abdi_processargs
import phlsys_statusline


def getFromfilePrefixChars():
    return '@'


def setupParser(parser):

    parser.add_argument(
        '--instance-uri',
        metavar="URI",
        type=str,
        required=True,
        help="instance to connect to, e.g. http://127.0.0.1")

    parser.add_argument(
        '--arcyd-user',
        metavar="USER",
        type=str,
        required=True,
        help="username for Arcyd to use")

    parser.add_argument(
        '--arcyd-cert',
        metavar="CERT",
        type=str,
        required=True,
        help="Phabricator Conduit API certificate to use, this is the "
        "value that you will find in your user account in Phabricator "
        "at: http://your.server.example/settings/panel/conduit/. "
        "It can also be found in ~/.arcrc.")

    parser.add_argument(
        '--arcyd-email',
        metavar="FROM",
        type=str,
        required=True,
        help="email address for Arcyd to send mails from")

    parser.add_argument(
        '--admin-email',
        metavar="TO",
        type=str,
        required=True,
        help="email address to send important system events to")

    parser.add_argument(
        '--repo-desc',
        metavar="DESC",
        type=str,
        required=True,
        help="description to use in emails")

    parser.add_argument(
        '--repo-path',
        metavar="PATH",
        type=str,
        required=True,
        help="path to the repository on disk")

    parser.add_argument(
        '--https-proxy',
        metavar="PROXY",
        type=str,
        help="proxy to use, if necessary")

    parser.add_argument(
        '--sleep-secs',
        metavar="TIME",
        type=int,
        default=60,
        help="time to wait between fetches")


def process(args):
    out = phlsys_statusline.StatusLine()

    while True:
        abdi_processargs.run_once(args, out)

        sleep_remaining = args.sleep_secs
        while sleep_remaining > 0:
            out.display("sleep (" + str(sleep_remaining) + " seconds) ")
            time.sleep(1)
            sleep_remaining -= 1


#------------------------------------------------------------------------------
# Copyright (C) 2012 Bloomberg L.P.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#------------------------------- END-OF-FILE ----------------------------------