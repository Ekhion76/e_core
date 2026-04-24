import { mount } from 'svelte'
import './app.css'
import NuiApp from './NuiApp.svelte'

const app = mount(NuiApp, {
  target: document.getElementById('app')!
})

export default app
