<template>
  <div id="app">
    <nav>
      <router-link to="/"><img alt="Vue logo" src="./assets/logo.png" height="64px"></router-link>
      <span>
        <router-link to="/wysiwyg">Wysiwyg</router-link>
        <router-link to="/about" class="ml-2">About</router-link>
      </span>
    </nav>
    <div class="container">
      <router-view/>
    </div>
  </div>
</template>

<style lang="scss">
body {
  margin: 0;
}

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}

nav {
  padding: .5rem 1rem;
  position: sticky;
  top: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #FFF;
  border-bottom: 1px solid #C9C9C9;
  z-index: 1000;

  a {
    font-weight: bold;
    color: #2c3e50;

    &.router-link-exact-active {
      color: #42b983;
    }
  }
}

.container {
  display: flex;
  margin-top: 100px;
  justify-content: center;
}

.ml-1 {
  margin-left: 5px;
}

.ml-2 {
  margin-left: 10px;
}

.mb-2 {
  margin-bottom: 10px;
}

button {
  border: none;
  cursor: pointer;

  &.active {
    background-color: #41b883;
  }
}
</style>
