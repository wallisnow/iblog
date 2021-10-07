---
title: "[ansible]add_host模块使用"
date: 2021-10-07 10:48:08
tags: ["ansible"]
categories: ["ansible"]
toc: true
---

# 需求
有时在使用ansible时, 有一些需求需要动态的加入一些host, 比如临时创建两台虚拟机, 在创建之前你也不知道他们的ip, 而在创建之后, 你需要用ansible进行一系列操作.这时把host写进内存就是一个比较好的方法.

# add_host 模块
这个模块就是ansible预置的模块, 提供动态添加host, 更直接的讲就是可以直接修改inventory文件, 当然这个inventory 文件并不是真正你使用的inventory, 而是内存中的inventory

# 例子
## 测试环境
原本的inventory 文件
```bash
[new]
192.168.50.146
192.168.50.109
```
这时, 写一个简单的play
```yaml
---
- name: hello world
  hosts: new
  gather_facts: false

  tasks:
    - name: test current hosts
      debug:
        msg: "{{item}} {{hostvars[item].inventory_hostname}}"
      loop: "{{ play_hosts }}"
```
<!--more-->
执行
```bash
ansible-playbook test_add_host.yml -v
```
结果
```bash

TASK [test current hosts] **************************************************************************************************************************************************************
skipping: [192.168.50.146] => (item=192.168.50.146)  => {"ansible_loop_var": "item", "item": "192.168.50.146"}
ok: [192.168.50.146] => (item=192.168.50.109) => {
    "msg": "192.168.50.109 192.168.50.109"
}
ok: [192.168.50.109] => (item=192.168.50.146) => {
    "msg": "192.168.50.146 192.168.50.146"
}
skipping: [192.168.50.109] => (item=192.168.50.109)  => {"ansible_loop_var": "item", "item": "192.168.50.109"}
```
可以看出这里我们有了两个最基本的host, 也就是 group 'new' 中定义的两个节点

## 使用add_host
```yaml
---
- name: hello world
  hosts: new
  gather_facts: false

  tasks:
    # 添加一个 ip 为192.168.50.109 的host 到 just_created_first, 并给定给一个变量 foo
    - name: Add host IP to group 'just_created_first' with variable foo=42
      add_host:
        name: 192.168.50.109
        groups: just_created_first 
        foo: 42
    # 添加一个 hostname 为node_in_memory 的host 到 just_created_second, 并指定链接方式为ssh
    - name: Add host name to group 'just_created_second' with variable
      add_host:
        name: node_in_memory
        ansible_host: "192.168.50.146"
        ansible_connection: ssh
        groups: just_created_second
    # 打印此时的 play_hosts
    - name: test current hosts
      debug:
        msg: "{{item}} {{hostvars[item].inventory_hostname}}"
      when: item != inventory_hostname
      loop: "{{ play_hosts }}"
    # 打印此时的 ansible_play_hosts
    - name: test current ansible hosts in memory
      debug:
        msg: "ansible_play_hosts : {{item}}, in inventory_dir: {{ inventory_dir }}"
      loop: "{{ ansible_play_hosts }}"
    # 查看当前所有的host变量
    - name: use hostname node_in_memory
      delegate_to: "{{ groups['just_created_second'][0] }}"
      run_once: true
      debug:
        msg: "{{ hostvars }}"
```

这里很多个步骤, 我们只看最后一个task的输出结果, 前面的task也只是为了分别查看部分变量. 最后一个打印了所有我们当前的host变量值, 也就是我们可以使用的host地址, 参数, 等等, 我们可以使用这些参数来进行操作
```bash
TASK [test host vars node_in_memory] ***************************************************************************************************************************************************
ok: [192.168.50.146 -> 192.168.50.146] => {
    "msg": {
        "192.168.50.109": {
            "ansible_check_mode": false, 
            "ansible_diff_mode": false, 
            "ansible_facts": {}, 
            "ansible_forks": 5, 
            "ansible_inventory_sources": [
                "/home/osboxes/ansible/helloworld/hosts"
            ], 
            "ansible_playbook_python": "/usr/bin/python2", 
            "ansible_run_tags": [
                "all"
            ], 
            "ansible_skip_tags": [], 
            "ansible_sudo_pass": "osboxes.org", 
            "ansible_verbosity": 1, 
            "ansible_version": {
                "full": "2.9.18", 
                "major": 2, 
                "minor": 9, 
                "revision": 18, 
                "string": "2.9.18"
            }, 
            "foo": 42, 
            "group_names": [
                "just_created_first", 
                "new"
            ], 
            "groups": {
                "all": [
                    "node_in_memory", 
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "just_created_first": [
                    "192.168.50.109"
                ], 
                "just_created_second": [
                    "node_in_memory"
                ], 
                "new": [
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "ungrouped": []
            }, 
            "inventory_dir": "/home/osboxes/ansible/helloworld", 
            "inventory_file": "/home/osboxes/ansible/helloworld/hosts", 
            "inventory_hostname": "192.168.50.109", 
            "inventory_hostname_short": "192", 
            "playbook_dir": "/home/osboxes/ansible/helloworld"
        }, 
        "192.168.50.146": {
            "ansible_check_mode": false, 
            "ansible_diff_mode": false, 
            "ansible_facts": {}, 
            "ansible_forks": 5, 
            "ansible_inventory_sources": [
                "/home/osboxes/ansible/helloworld/hosts"
            ], 
            "ansible_playbook_python": "/usr/bin/python2", 
            "ansible_run_tags": [
                "all"
            ], 
            "ansible_skip_tags": [], 
            "ansible_sudo_pass": "osboxes.org", 
            "ansible_verbosity": 1, 
            "ansible_version": {
                "full": "2.9.18", 
                "major": 2, 
                "minor": 9, 
                "revision": 18, 
                "string": "2.9.18"
            }, 
            "group_names": [
                "new"
            ], 
            "groups": {
                "all": [
                    "node_in_memory", 
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "just_created_first": [
                    "192.168.50.109"
                ], 
                "just_created_second": [
                    "node_in_memory"
                ], 
                "new": [
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "ungrouped": []
            }, 
            "inventory_dir": "/home/osboxes/ansible/helloworld", 
            "inventory_file": "/home/osboxes/ansible/helloworld/hosts", 
            "inventory_hostname": "192.168.50.146", 
            "inventory_hostname_short": "192", 
            "playbook_dir": "/home/osboxes/ansible/helloworld"
        }, 
        "node_in_memory": {
            "ansible_check_mode": false, 
            "ansible_connection": "ssh", 
            "ansible_diff_mode": false, 
            "ansible_facts": {}, 
            "ansible_forks": 5, 
            "ansible_host": "192.168.50.146", 
            "ansible_inventory_sources": [
                "/home/osboxes/ansible/helloworld/hosts"
            ], 
            "ansible_playbook_python": "/usr/bin/python2", 
            "ansible_run_tags": [
                "all"
            ], 
            "ansible_skip_tags": [], 
            "ansible_verbosity": 1, 
            "ansible_version": {
                "full": "2.9.18", 
                "major": 2, 
                "minor": 9, 
                "revision": 18, 
                "string": "2.9.18"
            }, 
            "group_names": [
                "just_created_second"
            ], 
            "groups": {
                "all": [
                    "node_in_memory", 
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "just_created_first": [
                    "192.168.50.109"
                ], 
                "just_created_second": [
                    "node_in_memory"
                ], 
                "new": [
                    "192.168.50.146", 
                    "192.168.50.109"
                ], 
                "ungrouped": []
            }, 
            "inventory_dir": null, 
            "inventory_file": null, 
            "inventory_hostname": "node_in_memory", 
            "inventory_hostname_short": "node_in_memory", 
            "playbook_dir": "/home/osboxes/ansible/helloworld"
        }
    }
}
```
可以看出, 此时,我们每个节点的host变量集合, 对于每台机器我们都有如下组别, 这里有一个我们特意使用node_in_memory的hostname, 没有使用节点ip,依然可以链接,原因就是我们在给定name时,也给定了ansible_host, 也就是ansible中 host文件的本身支持的变量. 
```bash
"groups": {
    "all": [
        "node_in_memory", 
        "192.168.50.146", 
        "192.168.50.109"
    ], 
    "just_created_first": [
        "192.168.50.109"
    ], 
    "just_created_second": [
        "node_in_memory"
    ], 
    "new": [
        "192.168.50.146", 
        "192.168.50.109"
    ], 
    "ungrouped": []
}
```
除了ansible_host, 我们也可以指定, ansible链接时的参数, 以ssh为例, 此时我们可以指定各种参数, 例如
```yaml
- name: Add hosts
  add_host:
    groups: "{{ myhost.groups }}"
    name: "{{ myhost.name }}"
    ansible_host: "{{ myhost.address }}"
    ansible_connection: ssh
    ansible_ssh_user: "{{ myhost.user }}"
    ansible_ssh_extra_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    ansible_ssh_private_key_file: "{{ myhost.ssh_priv_key_path }}"
    ansible_ssh_common_args: >-
      -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
      -W %h:%p -q -i {{ myhost.proxy.ssh_priv_key_path }}
      {{ myhost.proxy.user }}@{{ myhost.proxy.host }}'
```

# 结论
add_host解决了临时添加host的问题, 但由于其是写入内存中, 所以在使用时需要开发人员知晓当前的host信息, 所以开发中需要注意, 特别是当使用临时的组名, 很容易不知道当前这个组包含的节点, 所以注意灵活使用"{{ hostvars }}"来查看当前的inventory信息

# Reference
* https://docs.ansible.com/ansible/latest/collections/ansible/builtin/add_host_module.html