---
title: Mustache 模板语法
image: 1065.jpg
category: Document Writing
---

#### 变量

```
Template:

* {{name}}
* {{age}}
* {{company}}
* {{{company}}}

Hash:

{
  "name": "Chris",
  "company": "<b>GitHub</b>"
}

Output:

* Chris
*
* &lt;b&gt;GitHub&lt;/b&gt;
* <b>GitHub</b>
```

#### 判断

```
Template:

Shown.
{{#person}}
  Never shown!
{{/person}}

Hash:

{
  "person": false
}

Output:

Shown.
```

#### 取反

```
Template:

{{^repo}}
  No repos :(
{{/repo}}

Hash:

{
  "repo": false
}

Output:

No repos :(
```

#### 循环

```
Template:

{{#repo}}
  <b>{{name}}</b>
{{/repo}}

Hash:

{
  "repo": [
    { "name": "resque" },
    { "name": "hub" },
    { "name": "rip" }
  ]
}

Output:

<b>resque</b>
<b>hub</b>
<b>rip</b>
```

导入

```
base.mustache:
<h2>Names</h2>
{{#names}}
  {{> user}}
{{/names}}

user.mustache:
<strong>{{name}}</strong>

Expanded output:

<h2>Names</h2>
{{#names}}
  <strong>{{name}}</strong>
{{/names}}
```
