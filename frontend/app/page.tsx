import { getAllRecords, getAllProjects, getAllTags } from '@/lib/records'
import RecordList from '@/components/RecordList'

export default async function HomePage() {
  const records = getAllRecords()
  const projects = getAllProjects()
  const tags = getAllTags()

  if (records.length === 0) {
    return (
      <div className="page">
        <main className="main" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1 }}>
          <div className="empty-state">
            <div className="empty-state__icon">📭</div>
            <div className="empty-state__title">記録がまだありません</div>
            <div className="empty-state__description">
              <code>./scripts/new-record.sh</code> または{' '}
              <code>./scripts/auto-record.sh</code> を実行して記録を作成してください。
            </div>
          </div>
        </main>
      </div>
    )
  }

  return (
    <RecordList
      records={records}
      projects={projects}
      tags={tags}
    />
  )
}
