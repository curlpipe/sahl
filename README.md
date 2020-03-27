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

### A brand new templating system
In many websites there are repeated parts e.g. a navbar or footer. So with sahl we added a templating system.
Write the sahl you want to use in multiple pages and then just import it and sahl will drop in the code in the correct place.
This means that when you update your templates, the entire sahl project updates to match, no more copy, pasting and correcting everywhere.

Lets say you write some navbar code in `nav.sahl`.
```
nav {
    // navbar code here
}
```
To use it in any other sahl file in the same directory, do this in the target sahl file:
```
@nav.sahl
```
And all the code in nav.sahl will be placed in the position of the @

### Expanding your website is no longer verbose to set up
#### Allows you to import css frameworks, js modules and fonts with ease
In HTML:
```
<link href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
<link href="https://fonts.googleapis.com/css?family=Open+Sans" rel="stylesheet" type="text/css">
<h1>Hello World</h1>
```
In SAHL:
```
@bootstrap
@opensans
h1 Hello World
```
