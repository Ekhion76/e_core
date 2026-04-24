import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

// https://vite.dev/config/
// Egyesített NUI: `ui_page` → `html/web/index.html`
export default defineConfig({
  plugins: [svelte()],
  base: './',
  build: {
    outDir: '../html/web',
    emptyOutDir: true,
    chunkSizeWarningLimit: 700
  }
})
