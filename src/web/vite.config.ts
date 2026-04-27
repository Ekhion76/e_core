import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

// https://vite.dev/config/
// Prod: `fxmanifest.lua` `ui_page` -> `src/web/dist/index.html` + `npm run build`.
// Dev: `ui_page 'http://127.0.0.1:5173/'` + `npm run dev` (server alább).
export default defineConfig({
  plugins: [svelte()],
  base: './',
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
    origin: 'http://127.0.0.1:5173'
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    chunkSizeWarningLimit: 700
  }
})
