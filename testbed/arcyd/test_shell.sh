###############################################################################
# test shell for Arcyd, aimed at letting you poke around interactively
###############################################################################

set +x
set -e
trap "echo FAILED!; exit 1" EXIT

# cd to the dir of this script, so paths are relative
cd "$(dirname "$0")"

pokeloop="$(pwd)/poke_loop.sh"
arcyd="$(pwd)/../../proto/arcyd"
arcyon="$(pwd)/../../bin/arcyon"

phaburi="http://127.0.0.1"
arcyduser='phab'
arcydcert=xnh5tpatpfh4pff4tpnvdv74mh74zkmsualo4l6mx7bb262zqr55vcachxgz7ru3lrv\
afgzquzl3geyjxw426ujcyqdi2t4ktiv7gmrtlnc3hsy2eqsmhvgifn2vah2uidj6u6hhhxo2j3y2w\
6lcsehs2le4msd5xsn4f333udwvj6aowokq5l2llvfsl3efcucraawtvzw462q2sxmryg5y5rpicdk\
3lyr3uvot7fxrotwpi3ty2b2sa2kvlpf

arcyoncreds="--uri ${phaburi} --user ${arcyduser} --cert ${arcydcert}"

tempdir=$(mktemp -d)
olddir=$(pwd)
cd ${tempdir}

mail="${olddir}/savemail"
reporter="${olddir}/savereport"

mkdir origin
cd origin
    git init --bare
    mv hooks/post-update.sample hooks/post-update

    # run an http server for Git in the background, for snooping
    python -m SimpleHTTPServer 8000 < /dev/null > webserver.log 2>&1 &
    webserver_pid=$!
cd ..

git init --bare origin2

git clone origin dev
cd dev
git config user.name 'Bob User'
git config user.email 'bob@server.test'

echo 'feature=$(tr -dc "[:alpha:]" < /dev/urandom | head -c 8)' >> poke.sh
echo 'branch="arcyd-review/${feature}/master"' >> poke.sh
echo 'echo poke feature ${feature}' >> poke.sh
echo 'git checkout -b ${branch} origin/master' >> poke.sh
echo 'touch ${feature}' >> poke.sh
echo 'git add .' >> poke.sh
echo 'git commit -am "poked feature ${feature}"' >> poke.sh
echo 'git push -u origin ${branch}' >> poke.sh

echo "arcyon='${arcyon}'" >> accept.sh
echo "arcyoncreds='${arcyoncreds}'" >> accept.sh
echo 'revisionid=$(${arcyon} query --max-results 1 --statuses "Needs Review" --format-type ids ${arcyoncreds})' >> accept.sh
echo 'if [ -n "$revisionid" ]; then' >> accept.sh
echo '${arcyon} comment ${revisionid} --action accept ${arcyoncreds}' >> accept.sh
echo 'fi' >> accept.sh

chmod +x poke.sh
chmod +x accept.sh

git add .
git commit -m 'intial commit'
git push origin master
cd ..

git clone origin2 dev2
cd dev2
git config user.name 'Unseen User'
git config user.email 'unseen@server.test'

touch README
git add README

git commit -m 'intial commit'
git push origin master
cd ..

mkdir arcyd
cd arcyd
    $arcyd init \
        --sleep-secs 1 \
        --arcyd-email 'arcyd@localhost' \
        --sendmail-binary ${mail} \
        --sendmail-type catchmail \
        --external-report-command "${reporter}"

    echo '' >> configfile  # the generated file won't end in carriage return
    echo '--external-error-logger' >> configfile
    echo "on_system_error.sh" >> configfile

    touch system_error.log
    echo '#! /usr/bin/env bash' > on_system_error.sh
    echo 'echo $1 >> system_error.log' >> on_system_error.sh
    echo 'echo $2 >> system_error.log' >> on_system_error.sh
    echo 'echo >> system_error.log' >> on_system_error.sh
    chmod +x on_system_error.sh

    $arcyd add-phabricator \
        --name localhost \
        --instance-uri http://127.0.0.1/api/ \
        --review-url-format 'http://127.0.0.1/D{review}' \
        --admin-emails 'local-phab-admin@localhost' \
        --arcyd-user phab \
        --arcyd-cert \
xnh5tpatpfh4pff4tpnvdv74mh74zkmsualo4l6mx7bb262zqr55vcachxgz7ru3lrvafgzqu\
zl3geyjxw426ujcyqdi2t4ktiv7gmrtlnc3hsy2eqsmhvgifn2vah2uidj6u6hhhxo2j3y2w6lcseh\
s2le4msd5xsn4f333udwvj6aowokq5l2llvfsl3efcucraawtvzw462q2sxmryg5y5rpicdk3lyr3u\
vot7fxrotwpi3ty2b2sa2kvlpf

    $arcyd add-repohost \
        --name fs1 \
        --repo-url-format '../{}' \
        --repo-snoop-url-format 'http://localhost:8000/info/refs' \
        --branch-url-format 'http://my.git/gitweb?p={repo_url}.git;a=log;h=refs/heads/{branch}' \
        --admin-emails 'local-git-admin2@localhost' 'local-git-admin@localhost'

    $arcyd add-repohost \
        --name fs2 \
        --repo-url-format '../{}' \
        --branch-url-format 'http://my.git/gitweb?p={repo_url}.git;a=log;h=refs/heads/{branch}' \
        --admin-emails 'local-git-admin2@localhost' 'local-git-admin@localhost'

    $arcyd add-repo localhost fs1 origin
    $arcyd add-repo localhost fs2 origin2

cd ..

# add a second arcyd instance
mkdir arcyd2
cd arcyd2
    $arcyd init \
        --sleep-secs 1 \
        --arcyd-email 'arcyd@localhost' \
        --sendmail-binary ${mail} \
        --sendmail-type catchmail \
        --external-report-command "${reporter}"

    $arcyd add-phabricator \
        --name localhost \
        --instance-uri http://127.0.0.1/api/ \
        --review-url-format 'http://127.0.0.1/D{review}' \
        --admin-emails 'local-phab-admin@localhost' \
        --arcyd-user phab \
        --arcyd-cert \
xnh5tpatpfh4pff4tpnvdv74mh74zkmsualo4l6mx7bb262zqr55vcachxgz7ru3lrvafgzqu\
zl3geyjxw426ujcyqdi2t4ktiv7gmrtlnc3hsy2eqsmhvgifn2vah2uidj6u6hhhxo2j3y2w6lcseh\
s2le4msd5xsn4f333udwvj6aowokq5l2llvfsl3efcucraawtvzw462q2sxmryg5y5rpicdk3lyr3u\
vot7fxrotwpi3ty2b2sa2kvlpf

    $arcyd add-repohost \
        --name fs1 \
        --repo-url-format '../{}' \
        --repo-snoop-url-format 'http://localhost:8000/info/refs' \
        --branch-url-format 'http://my.git/gitweb?p={repo_url}.git;a=log;h=refs/heads/{branch}' \
        --admin-emails 'local-git-admin2@localhost' 'local-git-admin@localhost'

    $arcyd add-repohost \
        --name fs2 \
        --repo-url-format '../{}' \
        --branch-url-format 'http://my.git/gitweb?p={repo_url}.git;a=log;h=refs/heads/{branch}' \
        --admin-emails 'local-git-admin2@localhost' 'local-git-admin@localhost'

    $arcyd add-repo localhost fs1 origin
    $arcyd add-repo localhost fs2 origin2

cd ..

# run arcyd instaweb in the background
${arcyd} \
    instaweb \
    --report-file arcyd/var/status/arcyd_status.json \
    --repo-file-dir arcyd/var/status \
    --port 8001 \
&
instaweb_pid=$!

# run arcyd in the background
cd arcyd
${arcyd} start
cd ..

function cleanup() {

    set +e

    echo $instaweb_pid
    kill $instaweb_pid
    wait $instaweb_pid

    # kill arcyd
    cd ${tempdir}
    cd arcyd
    ${arcyd} stop -f
    cd ..

    echo $webserver_pid
    kill $webserver_pid
    wait $webserver_pid

    # display the sent mails
    pwd
    cat arcyd/savemail.txt
    cat arcyd/system_error.log
    cat arcyd/var/log/info

    # clean up
    cd ${olddir}
    rm -rf ${tempdir}

    echo finished.
}

trap cleanup EXIT
cd dev
    /usr/bin/env bash
cd -
trap - EXIT
cleanup
# -----------------------------------------------------------------------------
# Copyright (C) 2013-2014 Bloomberg Finance L.P.
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
