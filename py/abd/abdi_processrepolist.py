"""Process a list of repository arguments."""
# =============================================================================
# CONTENTS
# -----------------------------------------------------------------------------
# abdi_processrepolist
#
# Public Functions:
#   do
#
# -----------------------------------------------------------------------------
# (this contents block is generated, edits will be lost)
# =============================================================================

from __future__ import absolute_import

import functools
import os
import sys

import phlsys_git
import phlsys_scheduleunreliables
import phlsys_strtotime
import phlurl_watcher

import abdt_exhandlers
import abdt_fs
import abdt_git

import abdi_operation
import abdi_processrepoargs


def do(
        repo_configs,
        sys_admin_emails,
        kill_file,
        sleep_secs,
        is_no_loop,
        external_report_command,
        reporter):

    # TODO: test write access to repos here

    operations = []
    conduits = {}

    fs_accessor = abdt_fs.make_default_accessor()
    url_watcher_wrapper = phlurl_watcher.FileCacheWatcherWrapper(
        fs_accessor.layout.urlwatcher_cache_path)

    # refresh cache after loading and before any repos are processed, otherwise
    # we may not pull when we need to on the first run around the loop.
    # TODO: wrap in usual retry handlers so that we can start up in unstable
    #       environments
    url_watcher_wrapper.watcher.refresh()

    _append_operations_for_repos(
        operations,
        reporter,
        conduits,
        url_watcher_wrapper,
        sys_admin_emails,
        repo_configs)

    _append_interrupt_operations(
        operations,
        kill_file,
        sleep_secs,
        reporter)

    operations.append(
        abdi_operation.RefreshCaches(
            conduits, url_watcher_wrapper.watcher, reporter))

    if external_report_command:
        full_path = os.path.abspath(external_report_command)
        operations.append(
            abdi_operation.CycleReportJson(full_path))

    _process_operations(is_no_loop, operations)


def _process_operations(is_no_loop, operations):
    if is_no_loop:
        new_ops = phlsys_scheduleunreliables.process_once(list(operations))
        if new_ops != set(operations):
            print 'ERROR: some operations failed'
            sys.exit(1)
    else:
        phlsys_scheduleunreliables.process_loop_forever(list(operations))


def _append_interrupt_operations(
        operations,
        kill_file,
        sleep_secs,
        reporter):

    operations.append(
        abdi_operation.CheckSpecialFiles(
            kill_file))

    operations.append(
        abdi_operation.Sleep(
            sleep_secs, reporter))


def _append_operations_for_repos(
        operations,
        reporter,
        conduits,
        url_watcher_wrapper,
        sys_admin_emails,
        repo_configs):

    strToTime = phlsys_strtotime.duration_string_to_time_delta
    retry_delays = [strToTime(d) for d in ["10 minutes", "1 hours"]]

    for repo_name, repo_args in repo_configs:

        # create a function to update this particular repo.
        #
        # use partial to ensure we capture the value of the variables,
        # note that a closure would use the latest value of the variables
        # rather than the value at declaration time.
        abd_repo = abdt_git.Repo(
            phlsys_git.Repo(repo_args.repo_path),
            "origin",
            repo_args.repo_desc)
        process_func = functools.partial(
            _process_single_repo,
            abd_repo,
            repo_name,
            repo_args,
            reporter,
            conduits,
            url_watcher_wrapper)

        on_exception_delay = abdt_exhandlers.make_exception_delay_handler(
            sys_admin_emails, reporter, repo_name)

        operation = phlsys_scheduleunreliables.DelayedRetryNotifyOperation(
            process_func,
            list(retry_delays),  # make a copy to be sure
            on_exception_delay)

        operations.append(operation)


def _process_single_repo(
        abd_repo,
        repo_name,
        repo_args,
        reporter,
        conduits,
        url_watcher_wrapper):

    watcher = url_watcher_wrapper.watcher
    abdi_processrepoargs.do(
        abd_repo, repo_name, repo_args, reporter, conduits, watcher)

    # save the urlwatcher cache
    url_watcher_wrapper.save()


# -----------------------------------------------------------------------------
# Copyright (C) 2014 Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------ END-OF-FILE ----------------------------------
