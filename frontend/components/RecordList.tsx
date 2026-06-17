'use client'

import { useState, useMemo } from 'react'
import Link from 'next/link'
import type { QARecord, RecordStatus } from '@/types'

interface Props {
  records: QARecord[]
  projects: string[]
  tags: string[]
}

const STATUS_LABELS: Record<RecordStatus, { label: string; icon: string }> = {
  resolved:   { label: 'resolved',   icon: '✅' },
  unresolved: { label: 'unresolved', icon: '❌' },
  workaround: { label: 'workaround', icon: '⚠️' },
}

export default function RecordList({ records, projects, tags }: Props) {
  const [query, setQuery] = useState('')
  const [activeProject, setActiveProject] = useState<string | null>(null)
  const [activeStatus, setActiveStatus] = useState<RecordStatus | null>(null)
  const [activeTags, setActiveTags] = useState<string[]>([])

  const filtered = useMemo(() => {
    const q = query.toLowerCase()
    return records.filter((r) => {
      if (activeProject && r.frontmatter.project !== activeProject) return false
      if (activeStatus && r.frontmatter.status !== activeStatus) return false
      if (activeTags.length > 0 && !activeTags.every((t) => r.frontmatter.tags.includes(t))) return false
      if (q) {
        const haystack = [
          r.title,
          r.frontmatter.project,
          r.frontmatter.task,
          r.excerpt,
          ...r.frontmatter.tags,
        ].join(' ').toLowerCase()
        if (!haystack.includes(q)) return false
      }
      return true
    })
  }, [records, query, activeProject, activeStatus, activeTags])

  const projectCounts = useMemo(() =>
    Object.fromEntries(projects.map((p) => [p, records.filter((r) => r.frontmatter.project === p).length])),
    [records, projects]
  )

  const statusCounts = useMemo(() => ({
    resolved:   records.filter((r) => r.frontmatter.status === 'resolved').length,
    unresolved: records.filter((r) => r.frontmatter.status === 'unresolved').length,
    workaround: records.filter((r) => r.frontmatter.status === 'workaround').length,
  }), [records])

  const toggleTag = (tag: string) =>
    setActiveTags((prev) => prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag])

  return (
    <div className="page">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar__section">
          <div className="sidebar__heading">プロジェクト</div>
          <button
            className={`sidebar__item ${!activeProject ? 'sidebar__item--active' : ''}`}
            onClick={() => setActiveProject(null)}
          >
            すべて
            <span className="sidebar__count">{records.length}</span>
          </button>
          {projects.map((p) => (
            <button
              key={p}
              className={`sidebar__item ${activeProject === p ? 'sidebar__item--active' : ''}`}
              onClick={() => setActiveProject(activeProject === p ? null : p)}
            >
              <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p}</span>
              <span className="sidebar__count">{projectCounts[p]}</span>
            </button>
          ))}
        </div>

        <div className="sidebar__divider" />

        <div className="sidebar__section">
          <div className="sidebar__heading">ステータス</div>
          {(['resolved', 'unresolved', 'workaround'] as RecordStatus[]).map((s) => (
            statusCounts[s] > 0 && (
              <button
                key={s}
                className={`sidebar__item ${activeStatus === s ? 'sidebar__item--active' : ''}`}
                onClick={() => setActiveStatus(activeStatus === s ? null : s)}
              >
                <span>{STATUS_LABELS[s].icon} {STATUS_LABELS[s].label}</span>
                <span className="sidebar__count">{statusCounts[s]}</span>
              </button>
            )
          ))}
        </div>

        {tags.length > 0 && (
          <>
            <div className="sidebar__divider" />
            <div className="sidebar__section">
              <div className="sidebar__heading">タグ</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', padding: '0 4px' }}>
                {tags.map((t) => (
                  <button
                    key={t}
                    className={`filter-chip ${activeTags.includes(t) ? 'filter-chip--active' : ''}`}
                    onClick={() => toggleTag(t)}
                  >
                    {t}
                  </button>
                ))}
              </div>
            </div>
          </>
        )}
      </aside>

      {/* Main */}
      <main className="main">
        {/* Search */}
        <div className="search">
          <span className="search__icon">🔍</span>
          <input
            className="search__input"
            type="text"
            placeholder="タイトル、タグ、本文で検索…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoFocus
          />
          {query && (
            <button className="search__clear" onClick={() => setQuery('')}>✕</button>
          )}
        </div>

        {/* Active filters display */}
        {(activeProject || activeStatus || activeTags.length > 0) && (
          <div className="filters" style={{ marginBottom: '12px' }}>
            <span className="filters__label">フィルタ:</span>
            {activeProject && (
              <button className="filter-chip filter-chip--active" onClick={() => setActiveProject(null)}>
                📁 {activeProject} ✕
              </button>
            )}
            {activeStatus && (
              <button className="filter-chip filter-chip--active" onClick={() => setActiveStatus(null)}>
                {STATUS_LABELS[activeStatus].icon} {activeStatus} ✕
              </button>
            )}
            {activeTags.map((t) => (
              <button key={t} className="filter-chip filter-chip--active" onClick={() => toggleTag(t)}>
                {t} ✕
              </button>
            ))}
            <button
              className="filter-chip"
              onClick={() => { setActiveProject(null); setActiveStatus(null); setActiveTags([]); setQuery('') }}
              style={{ marginLeft: 'auto' }}
            >
              すべてクリア
            </button>
          </div>
        )}

        {/* Results */}
        <div className="record-list">
          <div className="record-list__meta">
            {filtered.length === records.length
              ? `${records.length} 件の記録`
              : `${filtered.length} / ${records.length} 件`}
          </div>

          {filtered.length === 0 ? (
            <div className="empty-state">
              <div className="empty-state__icon">🔍</div>
              <div className="empty-state__title">記録が見つかりませんでした</div>
              <div className="empty-state__description">
                検索条件やフィルタを変更して再度お試しください
              </div>
            </div>
          ) : (
            filtered.map((r) => (
              <Link
                key={r.href}
                href={r.href}
                className={`record-card record-card--${r.frontmatter.status}`}
              >
                <div className="record-card__header">
                  <span className="record-card__title">{r.title}</span>
                  <span className={`status-badge status-badge--${r.frontmatter.status}`}>
                    {(STATUS_LABELS[r.frontmatter.status] ?? STATUS_LABELS.unresolved).icon} {r.frontmatter.status}
                  </span>
                </div>
                {r.excerpt && (
                  <p className="record-card__excerpt">{r.excerpt}</p>
                )}
                <div className="record-card__footer">
                  <span className="record-card__project">{r.frontmatter.project}</span>
                  <div className="record-card__tags">
                    {r.frontmatter.tags.slice(0, 4).map((t) => (
                      <span key={t} className="tag">{t}</span>
                    ))}
                  </div>
                  <span className="record-card__date">{r.frontmatter.date}</span>
                </div>
              </Link>
            ))
          )}
        </div>
      </main>
    </div>
  )
}
