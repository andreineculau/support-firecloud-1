#!/usr/bin/env bash
set -euo pipefail

GID_INDEX=$((GID_INDEX + 1))
cat /etc/group | cut -d":" -f3 | grep -q "^${GID_INDEX}$" || {
    ${SUPPORT_FIRECLOUD_DIR}/bin/linux-addgroup --gid ${GID_INDEX} ${GNAME}
}
GNAME_REAL=$(getent group ${GID_INDEX} | cut -d: -f1)

UID_INDEX=$((UID_INDEX + 1))
${SUPPORT_FIRECLOUD_DIR}/bin/linux-adduser \
    --uid ${UID_INDEX} \
    --ingroup ${GNAME_REAL} \
    --home /home/${UNAME} \
    --shell /bin/sh \
    --disabled-password \
    ${UNAME}
! cat /etc/group | cut -d":" -f1 | grep -q "^sudo$" || ${SUPPORT_FIRECLOUD_DIR}/bin/linux-adduser2group ${UNAME} sudo
echo "${UNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "Defaults:${UNAME} !env_reset" >> /etc/sudoers
echo "Defaults:${UNAME} !secure_path" >> /etc/sudoers

# POST-BOOTSTRAP
[[ -e /home/${UNAME}/.bashrc ]] || cat <<EOF >> /home/${UNAME}/.bashrc
# If not running interactively, don't do anything
[[ $- = *i* ]] || return
EOF
cat /home/${UNAME}/.bashrc | grep -q "\.bash_aliases" || cat <<EOF >> /home/${UNAME}/.bashrc
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
[[ ! -f ~/.bash_aliases ]] || . ~/.bash_aliases
EOF
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.bashrc

cat <<EOF >> /home/${UNAME}/.bash_aliases
# poor-man version of sh/exe.inc.sh:sh_shellopts
OPTS_STATE="\$(set +o); \$(shopt -p)"
source ${SUPPORT_FIRECLOUD_DIR}/bootstrap/brew-util/env.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/sh/dev.inc.sh
# revert any shell options set in the scripts above
eval "\${OPTS_STATE}"; unset OPTS_STATE
EOF
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.bash_aliases

mkdir -p /home/${UNAME}/.ssh
chmod 700 /home/${UNAME}/.ssh
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.ssh

echo -e "Host github.com\n  StrictHostKeyChecking yes\n  CheckHostIP no" >/home/${UNAME}/.ssh/config
chmod 600 /home/${UNAME}/.ssh/config
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.ssh/config

echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >/home/${UNAME}/.ssh/known_hosts # editorconfig-checker-disable-line
chmod 600 /home/${UNAME}/.ssh/known_hosts
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.ssh/known_hosts

touch /home/${UNAME}/.sudo_as_admin_successful
chown ${UID_INDEX}:${GID_INDEX} /home/${UNAME}/.sudo_as_admin_successful
