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

/**
 * Wrapper aligned to common NUI naming.
 * Uses `preferredPath` and can fall back to a known legacy endpoint.
 */
export async function fetchNui(
  preferredPath: string,
  body: Record<string, unknown> = {},
  legacyPath?: string
): Promise<void> {
  const call = async (path: string): Promise<void> => {
    const response = await fetch(`https://${getResourceName()}/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body)
    })
    if (!response.ok) {
      throw new Error(`NUI request failed (${path}): ${response.status}`)
    }
  }

  try {
    await call(preferredPath)
  } catch (error) {
    if (!legacyPath || legacyPath === preferredPath) {
      throw error
    }
    await call(legacyPath)
  }
}
