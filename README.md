# pxl



## WASM

```bash
rustup target add wasm32-unknown-unknown
cargo build --example empty --target wasm32-unknown-unknown
```

And then use the following .html to load .wasm:

<details><summary>index.html</summary>

```html
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>TITLE</title>
    <style>
        html,
        body,
        canvas {
            margin: 0px;
            padding: 0px;
            width: 100%;
            height: 100%;
            overflow: hidden;
            position: absolute;
            background: black;
            z-index: 0;
        }
    </style>
</head>

<body>
    <canvas id="glcanvas" tabindex='1'></canvas>
    <!-- Minified and statically hosted version of https://github.com/not-fl3/miniquad/blob/master/native/sapp-wasm/js/gl.js -->
    <script src="https://not-fl3.github.io/miniquad-samples/gl.js"></script>
    <script>load("quad.wasm");</script> <!-- Your compiled wasm file -->
</body>

</html>
```
</details>

One of the ways to server static .wasm and .html:

```no-run
cargo install basic-http-server
basic-http-server .
```
