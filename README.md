Kubernetes Operator for Tower Config
=========

Simple [Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) to Configure Ansible Tower by Red Hat.  
This Operator is build using the [operator framework](https://operatorframework.io/), and will ensure the configuration of Ansible Tower and AWX based on Custom Resources Definitions describing the desired configurations.

# Dependencies
------------

All CRDs within this operator depend on a _Secret_ being defined within the desired namespace and this secret name must be given along with any of the CRs that wish, the _Secret_ itself has a particular k/v format:

```YAML
---
apiVersion: v1
kind: Secret
metadata:
  name: toweraccess
  namespace: myproject
  type: Opaque
stringData:
  token: XXXXX
  host: https://tower.victorock.io
  verify_ssl: false
```

## [Building and Push](https://sdk.operatorframework.io/docs/building-operators/ansible/quickstart/#build-and-push-the-operator-image)
---------

Use the built-in Makefile targets to build and push your operator. Make sure to define IMG when you call make:

```
make docker-build docker-push IMG=<some-registry>/<project-name>:<tag>
```

> NOTE: To allow the cluster pull the image the repository needs to be set as public or you must configure an image pull secret.


## [Install and Run](https://sdk.operatorframework.io/docs/building-operators/ansible/quickstart/#run-the-operator)
--------------------

Install the CRD and deploy the project to the cluster. Set IMG with make deploy to use the image you just pushed:

```
make install
make deploy IMG=<some-registry>/<project-name>:<tag>
```

## [Create](https://sdk.operatorframework.io/docs/building-operators/ansible/quickstart/#create-a-sample-custom-resource)
----------

Create a sample CR:

```
kubectl apply -f config/samples/tower_v1alpha1_organization.yaml
```


# Documentation
--------------

The following CRDs are implemented:

| Custom Resource Definition | Implementation | Custom Resource Samples |
|-------------------|--------------------|----------------------------------|
[Credentials](config/crd/bases/tower.ansible.com_credentials.yaml) | [credential](roles/credential/defaults/main.yml) | [Credential](config/samples/tower_v1alpha1_credential.yaml) |  
[CredentialInputSources](config/crd/bases/tower.ansible.com_credentialinputsources.yaml) | [credentialinputsource](roles/credentialinputsource/defaults/main.yml) | [CredentialInputSource](config/samples/tower_v1alpha1_credentialinputsource.yaml)
[CredentialTypes](config/crd/bases/tower.ansible.com_credentialtypes.yaml) | [credentialtype](roles/credentialtype/defaults/main.yml) | [CredentialType](config/samples/tower_v1alpha1_credentialtype.yaml) |
[Groups](config/crd/bases/tower.ansible.com_groups.yaml) | [group](roles/group/defaults/main.yml) | [Group](config/samples/tower_v1alpha1_group.yaml) |
[Inventories](config/crd/bases/tower.ansible.com_inventories.yaml) | [inventory](roles/inventory/defaults/main.yml) | [Inventory](config/samples/tower_v1alpha1_inventory.yaml) |
[InventorySources](config/crd/bases/tower.ansible.com_inventorysources.yaml) | [inventorysource](roles/inventorysource/defaults/main.yml) | [InventorySource](config/samples/tower_v1alpha1_inventorysource.yaml) |
[JobTemplates](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [jobtemplate](roles/jobtemplate/defaults/main.yml) | [JobTemplate](config/samples/tower_v1alpha1_jobtemplate.yaml) |
[Modules](config/crd/bases/tower.ansible.com_modules.yaml) | [module](roles/module/defaults/main.yml) | [Module](config/samples/tower_v1alpha1_module.yaml) |
[Organizations](config/crd/bases/tower.ansible.com_organizations.yaml) | [organization](roles/organization/defaults/main.yml) | [Organization](config/samples/tower_v1alpha1_organization.yaml) |
[Projects](config/crd/bases/tower.ansible.com_projects.yaml) | [project](roles/project/defaults/main.yml) | [Project](config/samples/tower_v1alpha1_project.yaml) |
[Roles](config/crd/bases/tower.ansible.com_roles.yaml) | [role](roles/role/defaults/main.yml) | [Role](config/samples/tower_v1alpha1_role.yaml) |
[Teams](config/crd/bases/tower.ansible.com_teams.yaml) | [team](roles/team/defaults/main.yml) | [Team](config/samples/tower_v1alpha1_team.yaml) |
[Users](config/crd/bases/tower.ansible.com_users.yaml) | [user](roles/user/defaults/main.yml) | [User](config/samples/tower_v1alpha1_user.yaml) |


 > The following CRDs have the structure but are not yet fully implemented:

| Custom Resource Definition | Implementation | Custom Resource Example |
|-|-|-|
[Notification](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [notification](roles/jobtemplate/defaults/main.yml) |
[Schedule](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [jobtemplate](roles/jobtemplate/defaults/main.yml) |
[WorkflowJobTemplateNode](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [jobtemplate](roles/jobtemplate/defaults/main.yml) |
[WorkflowJobTemplate](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [jobtemplate](roles/jobtemplate/defaults/main.yml) |
[WorkflowTemplate](config/crd/bases/tower.ansible.com_jobtemplates.yaml) | [jobtemplate](roles/jobtemplate/defaults/main.yml) |


## [Variables](https://sdk.operatorframework.io/docs/building-operators/ansible/development-tips/#extra-vars-sent-to-ansible)
------------

The extra vars that are sent to Ansible are managed by the operator. The spec section will pass along the key-value pairs as extra vars. This is equivalent to how above extra vars are passed in to ansible-playbook. The operator also passes along additional variables under the ansible_operator_meta field for the name of the CR and the namespace of the CR.  

For the CR example:  

```YAML
---
apiVersion: tower.ansible.com/v1alpha1
kind: Organization
metadata:
  name: "organization-sample"
spec:
  secret: toweraccess
  config:
    name: "{{ ansible_operator_meta.name }}"
    description: "sample"

```  

The structure passed to Ansible as extra vars is:

```JSON
{ "ansible_operator_meta": {
        "name": "<cr-name>",
        "namespace": "<cr-namespace>",
  },
  "secret": "toweraccess",
  "config": {
    "name": "{{ ansible_operator_meta.name }}",
    "description": "sample"
  },
  "_tower_ansible_com_organization": {
     <Full CR>
   },
  "_tower_ansible_com_organization_spec": {
     <Full CR .spec>
   },
}
```

`message` and `newParameter` are set in the top level as extra variables, and `ansible_operator_meta` provides the relevant metadata for the Custom Resource as defined in the operator.


## Examples
----------------

In this example we'll cover about how to create an organization in our Tower instance, using Organization CRD.  
First we have to create generate a token in order to be able to access Tower. We can do so using curl, as per example below:

```shell
curl -XPOST -k -H "Content-type: application/json" -d '{"description":"Personal Tower CLI token", "application":null, "scope":"write"}' https://admin:mypassword@tower.k8s.victorock.io/api/v2/users/admin/personal_tokens/ | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   588  100   509  100    79    180     28  0:00:02  0:00:02 --:--:--   208
{
  "id": 3,
  "type": "o_auth2_access_token",
  "url": "/api/v2/tokens/3/",
  "related": {
    "user": "/api/v2/users/3/",
    "activity_stream": "/api/v2/tokens/3/activity_stream/"
  },
  "summary_fields": {
    "user": {
      "id": 3,
      "username": "admin",
      "first_name": "",
      "last_name": ""
    }
  },
  "created": "2020-12-02T22:41:44.381981Z",
  "modified": "2020-12-02T22:41:44.745244Z",
  "description": "Personal Tower CLI token",
  "user": 3,
  "token": "LVckHx2g187SDdEAcUmsgUKjknFgWd",
  "refresh_token": null,
  "application": null,
  "expires": "3020-04-04T22:41:44.256763Z",
  "scope": "write"
}
```
> NOTE: The `jq` is not required, it is used here just to help with a more human-readable output.

Based on the output, note that we have the token (`LVckHx2g187SDdEAcUmsgUKjknFgWd`) has been generated by Tower, so we can do API calls to Tower without having to share usernames and passwords. As general guideline, you shall consider creating one token per application accessing your Tower.

Now that we have the token to access tower, we need to create a secret in our Kubernetes environment, so the operator can use to communicate with our tower instances. The `namespace` corresponds to the namespace where the other CRs will be created, the `name` is the name for the secret, the `token` is the token generated by Tower in our previous command, and finally the `verify_ssl` is to specify if we want or not to verify the ssl certificate when doing api requests.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: admin-tower.victorock.io
  namespace: ansible-platform
type: Opaque
stringData:
  token: "LVckHx2g187SDdEAcUmsgUKjknFgWd"
  host: "https://tower.victorock.io"
  verify_ssl: "false"
EOF
```

> NOTE: CRs will have an annotation with `tower.ansible.com/host: <host>`

With the credentials, we can start to create the CRs which represents the different configurations that we want to have applied in Tower. The example below shows the most basic CRs, the [Organization](config/samples/tower_v1alpha1_organization.yaml) and [Project](config/samples/tower_v1alpha1_project.yaml).


```YAML
---
apiVersion: tower.ansible.com/v1alpha1
kind: Organization
metadata:
  name: organization-sample
spec:
  secret: admin-tower.victorock.io
  config:
    name: "{{ ansible_operator_meta.name }}"
    description: "Organization"
---
apiVersion: tower.ansible.com/v1alpha1
kind: Project
metadata:
  name: project-sample
spec:
  secret: admin-tower.victorock.io
  config:
    name: "{{ ansible_operator_meta.name }}"
    scm_url: "https://github.com/victorock/ansible-devops/"
    scm_delete_on_update: no
    scm_type: git
    scm_update_on_launch: true
    organization: "organization-sample"

```

> You can save these CRs definitions in a single file, or in multiple files. Once they are saved, we use the `kubectl` command to apply them to our cluster.

```bash
kubectl apply -f <myfile>.yml
```

> You can save these CRs definitions in files, organized in multilevel directories. Once they are saved, we use the `kubectl` command with the recursive option to apply them to our cluster.

```bash
kubectl apply -f <mydir>/ -R
```
----
> NOTE: If you want to adopt a more gitops approach, and build a pipeline to get these definitions either in one or multiple clusters, that's exactly what i am doing in this example [here](https://github.com/victorock/k8s-gitops/).
----

TODO
-------

* Tests based on [ansible-role-tower-config](https://github.com/victorock/ansible-role-tower-config)
* Implementation of additional Tower CRDs: Settings, License, Workflow*
* Add additional tasks to delete all dependent CRDs when organization is deleted (finalized).
* Add strict mode capabilities, where only CRs configuration are kept.
* Refine the CRDs specifications based on docstring of Tower's modules.
* Refine the CRDs specifications based on the implementation asserts.

License
-------

GPLv3

Author Information
------------------

Victor da Costa
