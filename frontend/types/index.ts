export type RecordStatus = 'resolved' | 'unresolved' | 'workaround'

export interface RecordFrontmatter {
  date: string
  project: string
  task: string
  status: RecordStatus
  tags: string[]
  agent_used?: string[]
}

export interface QARecord {
  slug: string[]
  href: string
  frontmatter: RecordFrontmatter
  title: string
  content: string
  excerpt: string
}
