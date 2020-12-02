FROM quay.io/operator-framework/ansible-operator:v1.2.0

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY --chown=1001:0 watches.yaml ${HOME}/watches.yaml
COPY --chown=1001:0 roles/ ${HOME}/roles/
COPY --chown=1001:0 playbooks/ ${HOME}/playbooks/
