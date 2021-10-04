---
title: "[ansible]key value list 转 dictionary"
date: 2021-07-30T07:42:09+03:00
draft: false
tags: ["ansible", "ansible技巧"]
categories: ["ansible"]
author: "Jiang WU"
comments: true
---

# 需求
这两天我需要kubernetes 上面没有ready 的pod列出来, 然后对这些pod进行操作, 又要用到ansible, 思来想去不如来个map, 那么 python 或者ansible里面叫dict

<!--more-->
# 输入
这里有一个 kubectl get pods 得出的结果, 使用ansible的 shell, 我们需要处理其中的stdout, 或者stdout_lines
```
changed: [localhost -> fd00:eccd:0:a0a::5] => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "cmd": "/usr/local/bin/kubectl get pods  -n kube-system --field-selector spec.nodeName=poolalpha-worker-0-efggjjp-ansibd-01 -o custom-columns=NAME:.metadata.name,\"IS_READY\":.status.containerStatuses[].ready --no-headers",
    "delta": "0:00:00.475861",
    "end": "2021-07-29 19:37:41.515968",
    "invocation": {
        "module_args": {
            "_raw_params": "/usr/local/bin/kubectl get pods  -n kube-system --field-selector spec.nodeName=poolalpha-worker-0-efggjjp-ansibd-01 -o custom-columns=NAME:.metadata.name,\"IS_READY\":.status.containerStatuses[].ready --no-headers",
            "_uses_shell": true,
            "argv": null,
            "chdir": null,
            "creates": null,
            "executable": null,
            "removes": null,
            "stdin": null,
            "stdin_add_newline": true,
            "strip_empty_ends": true,
            "warn": true
        }
    },
    "rc": 0,
    "start": "2021-07-29 19:37:41.040107",
    "stderr": "",
    "stderr_lines": [],
    ...
    "stdout_lines": [
            "nginx-deployment-66b6c48dd5-4crpt    true",
            "nginx-deployment-66b6c48dd5-hqlxm    false"
    ]
}
```

# 需要的数据结构
我需要得到一个dict, pod_status, 然后key 是pod名, value是pod(容器)状态, 也就是这样滴->
```
"pod_status": {
            "nginx-deployment-66b6c48dd5-4crpt": "true",
            "nginx-deployment-66b6c48dd5-hqlxm": "false"
        }
```

# 具体实现
```
---
- name: test key value list to dict
  hosts: localhost
  gather_facts: false
  tasks:
    - name: set values
      set_fact:
        status_list:
          - "nginx-deployment-66b6c48dd5-4crpt              true"
          - "nginx-deployment-66b6c48dd5-hqlxm              false"
    - name: Set pod-status dict
      vars:
        pod: "{{ item.split()[0]|trim }}"
        status: "{{ item.split()[1]|trim }}"
      set_fact:
        pod_status: "{{ pod_status | default({}) | combine({pod : status})}}"
      loop: "{{ status_list }}"
```

* 这里使用了combine 函数+var 配合的方法, loop循环status_list, 所以会迭代两个item
  - "nginx-deployment-66b6c48dd5-4crpt              true"
  - "nginx-deployment-66b6c48dd5-4crpt              true"

* 这时再使用.split()来切割字符串, 那么其就会变成一个长度为 2 的数组, 也就是  item.split()[0] 和 item.split()[1], 里面分别装pod名和状态.
* 然后他们会被赋值到vars
* 然后通过combine函数生成数据结构为{pod : status} 的map, 也就是dictionary, 因为combine是merge的规则, 所以迭代后会叠加下去, 也就生成了
```
"pod_status": {
            "nginx-deployment-66b6c48dd5-4crpt": "true",
            "nginx-deployment-66b6c48dd5-hqlxm": "false"
        }
```
