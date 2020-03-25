# SAHL

## Super Abstract Hypertext Language

> A programmer-friendly hypertext markup language that compiles to HTML.

Let's be honest, nobody really likes HTML. For us it seemed to be a massive burden when it came to web development so we decided to create a language that allows one to glide through web development without tearing their hair out.

## Examples of HTML vs SAHL

### A Basic Title
In HTML:
```HTML
<h1>Example Title</h1>
```
In SAHL:
```
h1 Example Title
```

### A Title With Styling
In HTML:
```HTML
<h1 style="color: #0000ff; float: left;">Example Title</h1>
```
In SAHL:
```
h1(style: "color: #0000ff; float: left;") Example Title
```

### Multi-line elements
In HTML:
```HTML
<p>
  This element is on
  multiple lines.
</p>
```
In SAHL:
```
p {
  This element is on
  multiple lines.
}
```

### Nested Tags
In HTML:
```HTML
<p>This text is <b>bold</b>.</p>
```
In SAHL:
```
p This text is [b bold].
```

### Nested Tags + Multi-lines
In HTML:
```HTML
<div>
  <p>Here we have an <b>image</b>:</p>
  <img src="..." />
</div>
```
In SAHL:
```
div {
  p Here we have an [b image]:
  img(src: "...")
}
```
