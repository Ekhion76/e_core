export function getResourceName(): string {
  if (typeof GetParentResourceName === 'function') {
    return GetParentResourceName()
  }
  return 'e_core'
}

export function postNui(path: string, body: Record<string, unknown> = {}): void {
  void fetch(`https://${getResourceName()}/${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body)
  })
}
