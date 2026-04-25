<script lang="ts">
  type Props = {
    docsHomeUrl: string
  }

  let { docsHomeUrl }: Props = $props()
</script>

<div class="card">
  <div class="card-header doc-home-header">
    <h3>Dokumentacio</h3>
    <a href={docsHomeUrl} target="_blank" rel="noreferrer" class="secondary">GitHub Pages megnyitasa</a>
  </div>
  <p class="muted">
    A diagnostics hint-ek tovabbra is kozvetlenul a GitHub Pages megfelelo szekciojaira mutatnak.
  </p>
</div>
