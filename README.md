<center> <img src="assets/logo.png" width=300> </center>
<hr>

## Super Abstract Hypertext Language

> A programmer-friendly hypertext markup language that compiles to HTML.

Let's be honest, nobody really likes HTML. For us it seemed to be a massive burden when it came to web development so we decided to create a language that allows one to glide through web development without tearing their hair out.

## Why use SAHL over HTML?
HTML has been around as long as the world wide web and it is surprising to see that many technologies from around that time have been replaced by new alternatives that are miles ahead but HTML seems to be lacking behind. SAHL includes completely rewritten syntax from the ground up to provide a fresh start on web development. It also includes a templating system that not only removes the hassle of updating the same tags in multiple files but makes it so much faster to develop an awesome website.

## Features
 - 🚫 Abstracted end tags
 - 💻 Converts straight into HTML ready to be viewed in any browser
 - 🎨 Syntax suited to feel like CSS and Javascript
 - 🖋 An incredibly useful templating system allows modular markup
 - 🏎️ Speedy conversion taking only a couple of milliseconds
 - ⚠️ Invalid tag warnings to help identify issues
 - 💾 Drop in popular css & js frameworks as well as fonts with ease

## Using the compiler
When you have the compiler installed, you can use it like this:
```
ruby sahl.rb example.sahl
```

## Examples Of HTML vs SAHL

### A Basic Title
In HTML:
```HTML
<h1>Example Title</h1>
```
In SAHL:
```
.h1 Example Title
```

### Comments
In HTML:
```HTML
<!-- This is a comment -->

<!-- 
This is a comment
on multiple lines
-->
```
In SAHL:
```
// This is a comment

/*
This is a comment
on multiple lines
*/
```

### A Title With Styling
In HTML:
```HTML
<h1 style="color: #0000ff; float: left;">Example Title</h1>
```
In SAHL:
```
.h1[style: "color: #0000ff; float: left;"] Example Title
```

### Multi-attribute tags
In HTML:
```HTML
<h1 class="title" style="color: #0000ff">Title</h1>
```
In SAHL:
```
.h1[class: "title", style: "color: #0000ff"] Title
```

### Multi-line Elements
In HTML:
```HTML
<p>
  This element is on
  multiple lines.
</p>
```
In SAHL:
```
.p {
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
.p This text is .b {bold}.
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
.div {
  .p Here we have an .b {image}:
  .img[src: "..."]
}
```

### Templating with SAHL
In many websites there are repeated parts e.g. a navbar or footer. So with SAHL we added a templating system.
Write the SAHL you want to use in multiple pages in a seperate file. SAHL will drop in the code in the correct place when imported in another file.
This means that when you update your templates, the entire SAHL project updates to match. No more copy, pasting and correcting everywhere.

Lets say you write some navbar code in `nav.sahl`.
```
.nav {
  // navbar code here
}
```
To use it in any other SAHL file in the same directory, do this in the target SAHL file:
```
@nav.sahl
```
And all the code in nav.sahl will be placed in the file where you imported it.

### Creating a real world website is no longer verbose to set up
#### Allows you to import JS+CSS frameworks and fonts with ease
In HTML:
```HTML
<link href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
<link href="https://fonts.googleapis.com/css?family=Open+Sans" rel="stylesheet" type="text/css">
<h1>Hello World</h1>
```
In SAHL:
```
@bootstrap
@opensans
.h1 Hello World
```

Note: If you wish to use a custom method of obtaining external frameworks or add additional ones other than the default ones, you can create a json file called "sahl.json" where your sahl files are and then the compiler will read it and use those instead.

This is an example of what your sahl.json file should look like:
```JSON
{
   "opensans": ".link[href: \"https://fonts.googleapis.com/css?family=Open+Sans\", rel: \"stylesheet\", type: \"text/css\"]",
   "name": "SAHL / HTML goes here",
}
```
you can then just use `@` followed by the name in the json file, in any sahl file
