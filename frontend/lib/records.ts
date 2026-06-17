import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'
import type { QARecord, RecordFrontmatter } from '@/types'

const RECORDS_DIR = path.join(process.cwd(), '..', 'records')

function walkDir(dir: string): string[] {
  if (!fs.existsSync(dir)) return []
  const entries = fs.readdirSync(dir, { withFileTypes: true })
  const files: string[] = []
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      files.push(...walkDir(fullPath))
    } else if (
      entry.isFile() &&
      entry.name.endsWith('.md') &&
      entry.name !== '_index.md'
    ) {
      files.push(fullPath)
    }
  }
  return files
}

function filePathToSlug(filePath: string): string[] {
  const rel = path.relative(RECORDS_DIR, filePath)
  return rel.replace(/\.md$/, '').split(path.sep)
}

function formatDate(val: unknown): string {
  if (val instanceof Date) return val.toISOString().slice(0, 10)
  if (typeof val === 'string') return val
  return String(val ?? '')
}

function extractExcerpt(content: string, maxLen = 120): string {
  const text = content
    .replace(/^#{1,6}\s.+$/gm, '')
    .replace(/```[\s\S]*?```/g, '')
    .replace(/`[^`]+`/g, '')
    .replace(/\*\*(.+?)\*\*/g, '$1')
    .replace(/\*(.+?)\*/g, '$1')
    .replace(/\[(.+?)\]\(.+?\)/g, '$1')
    .replace(/^[-*>]\s/gm, '')
    .replace(/\n+/g, ' ')
    .trim()
  return text.length > maxLen ? text.slice(0, maxLen) + '…' : text
}

export function getAllRecords(): QARecord[] {
  const files = walkDir(RECORDS_DIR)
  const records: QARecord[] = []

  for (const filePath of files) {
    try {
      const raw = fs.readFileSync(filePath, 'utf-8')
      const { data, content } = matter(raw)
      const fm = data as Partial<RecordFrontmatter>

      const slug = filePathToSlug(filePath)
      const titleLine = content.match(/^#\s+(.+)$/m)
      const title = titleLine ? titleLine[1] : slug[slug.length - 1]
      const bodyWithoutTitle = content.replace(/^#\s+.+\n?/, '')

      records.push({
        slug,
        href: `/records/${slug.join('/')}`,
        frontmatter: {
          date: formatDate(fm.date),
          project: fm.project ?? slug[0] ?? '',
          task: fm.task ?? '',
          status: fm.status ?? 'unresolved',
          tags: Array.isArray(fm.tags) ? fm.tags : [],
          agent_used: fm.agent_used,
        },
        title,
        content: bodyWithoutTitle,
        excerpt: extractExcerpt(bodyWithoutTitle),
      })
    } catch {
      // skip malformed files
    }
  }

  return records.sort((a, b) => (a.frontmatter.date < b.frontmatter.date ? 1 : -1))
}

export function getRecordBySlug(slug: string[]): QARecord | null {
  const filePath = path.join(RECORDS_DIR, ...slug) + '.md'
  if (!fs.existsSync(filePath)) return null

  try {
    const raw = fs.readFileSync(filePath, 'utf-8')
    const { data, content } = matter(raw)
    const fm = data as Partial<RecordFrontmatter>
    const titleLine = content.match(/^#\s+(.+)$/m)
    const title = titleLine ? titleLine[1] : slug[slug.length - 1]
    const bodyWithoutTitle = content.replace(/^#\s+.+\n?/, '')

    return {
      slug,
      href: `/records/${slug.join('/')}`,
      frontmatter: {
        date: formatDate(fm.date),
        project: fm.project ?? slug[0] ?? '',
        task: fm.task ?? '',
        status: fm.status ?? 'unresolved',
        tags: Array.isArray(fm.tags) ? fm.tags : [],
        agent_used: fm.agent_used,
      },
      title,
      content: bodyWithoutTitle,
      excerpt: extractExcerpt(bodyWithoutTitle),
    }
  } catch {
    return null
  }
}

export function getAllProjects(): string[] {
  const records = getAllRecords()
  return [...new Set(records.map((r) => r.frontmatter.project))].sort()
}

export function getAllTags(): string[] {
  const records = getAllRecords()
  const tags = records.flatMap((r) => r.frontmatter.tags)
  return [...new Set(tags)].sort()
}
