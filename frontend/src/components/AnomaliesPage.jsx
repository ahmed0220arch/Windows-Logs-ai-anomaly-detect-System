import React, { useCallback, useEffect, useState } from 'react';
import { Radar, Search, Filter, Download } from 'lucide-react';
import api from '../services/api';
import AIDiagnosticAssistant from './AIDiagnosticAssistant';

const critConfig = {
  High: { bg: 'rgba(239,68,68,0.12)', text: '#ef4444', dot: '#ef4444' },
  Medium: { bg: 'rgba(245,158,11,0.12)', text: '#f59e0b', dot: '#f59e0b' },
  Low: { bg: 'rgba(59,130,246,0.12)', text: '#3b82f6', dot: '#3b82f6' },
};

function getCriticality(level) {
  const lvl = String(level).toUpperCase();
  if (['CRITICAL', 'ERROR', 'FATAL'].includes(lvl)) return 'High';
  if (lvl === 'WARNING') return 'Medium';
  return 'Low';
}

function formatDate(timestamp) {
  if (!timestamp) return '-';
  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return String(timestamp);
  return date.toLocaleString();
}



const ITEMS_PER_PAGE = 50;

export default function AnomaliesPage() {
  const [logs, setLogs] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [levelFilter, setLevelFilter] = useState('All');
  const [dateFilter, setDateFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('All');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchLogs = useCallback(async (overrides = {}) => {
    const targetPage = overrides.page !== undefined ? overrides.page : currentPage;
    const currentSearch = (overrides.search ?? appliedSearch).trim();
    const currentLevel = overrides.level ?? levelFilter;
    const currentDate = overrides.date ?? dateFilter;
    const currentType = overrides.type ?? typeFilter;

    const params = { page: targetPage, page_size: ITEMS_PER_PAGE, anomaly_only: true };
    if (currentLevel === 'High') {
      params.level = 'ERROR';
    } else if (currentLevel === 'Medium') {
      params.level = 'WARNING';
    } else if (currentLevel === 'Low') {
      params.level = 'INFO';
    }
    if (currentSearch) {
      params.search = currentSearch;
    }
    if (currentDate) {
      params.date = currentDate;
    }
    if (currentType !== 'All') {
      params.type = currentType;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await api.get('/api/logs', { params });
      setLogs(Array.isArray(response.data?.items) ? response.data.items : []);
      setTotalPages(response.data?.total_pages || 1);
      setTotalItems(response.data?.total || 0);
      setCurrentPage(response.data?.page || 1);
    } catch (err) {
      setError(err?.response?.data?.detail || 'Failed to load anomalies.');
      setLogs([]);
    } finally {
      setIsLoading(false);
    }
  }, [appliedSearch, levelFilter, dateFilter, typeFilter, currentPage]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const handleSearchKeyDown = (event) => {
    if (event.key === 'Enter') {
      const nextSearch = searchTerm.trim();
      setAppliedSearch(nextSearch);
      fetchLogs({ search: nextSearch, page: 1 });
    }
  };

  const handleExport = async (format = 'csv') => {
    const params = new URLSearchParams();
    params.set('anomaly_only', 'true');
    params.set('format', format);
    if (levelFilter !== 'All') params.set('level', levelFilter);
    if (appliedSearch) params.set('search', appliedSearch);
    if (dateFilter) params.set('date', dateFilter);
    if (typeFilter !== 'All') params.set('type', typeFilter);

    try {
      const token = localStorage.getItem('access_token');
      const baseUrl = api.defaults.baseURL || 'http://localhost:8000';
      const response = await fetch(
        `${baseUrl}/api/logs/export?${params.toString()}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (!response.ok) throw new Error('Export failed');
      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `anomalies_export_${new Date().toISOString().slice(0, 10)}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      setError('Failed to export anomalies.');
    }
  };

  const handlePageChange = (newPage) => {
    setCurrentPage(newPage);
    fetchLogs({ page: newPage });
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Radar size={20} style={{ color: '#818cf8' }} /> Anomalies
          </h1>
          <p className="text-[13px] mt-1" style={{ color: '#4a5490' }}>
            Search, filter, and export detected anomalies
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => handleExport('csv')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors"
            style={{
              background: '#131b4d',
              color: '#7a84b3',
              border: '1px solid #1a2555',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.color = '#c8d0e7';
              e.currentTarget.style.borderColor = '#3b82f6';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.color = '#7a84b3';
              e.currentTarget.style.borderColor = '#1a2555';
            }}
          >
            <Download size={15} />
            Export CSV
          </button>
          <button
            onClick={() => handleExport('pdf')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors"
            style={{
              background: '#131b4d',
              color: '#7a84b3',
              border: '1px solid #1a2555',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.color = '#c8d0e7';
              e.currentTarget.style.borderColor = '#ef4444';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.color = '#7a84b3';
              e.currentTarget.style.borderColor = '#1a2555';
            }}
          >
            <Download size={15} />
            Export PDF
          </button>
        </div>
      </div>

      <div
        className="flex flex-col md:flex-row gap-3 p-3 rounded-xl"
        style={{ background: '#0d1238', border: '1px solid #1a2555' }}
      >
        <div
          className="flex-1 flex items-center gap-2 px-3 py-2 rounded-lg"
          style={{ background: '#080d2a', border: '1px solid #1a2555' }}
        >
          <Search size={15} style={{ color: '#4a5490' }} />
          <input
            type="text"
            placeholder="Search anomalies by message..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            onKeyDown={handleSearchKeyDown}
            className="bg-transparent border-none outline-none text-sm w-full"
            style={{ color: '#c8d0e7' }}
          />
        </div>

        <div className="flex gap-3 overflow-x-auto pb-1 md:pb-0 hide-scrollbar">
          <div
            className="flex items-center gap-2 px-3 py-2 rounded-lg flex-shrink-0"
            style={{ background: '#080d2a', border: '1px solid #1a2555' }}
          >
            <Filter size={14} style={{ color: '#4a5490' }} />
            <select
              value={levelFilter}
              onChange={(e) => setLevelFilter(e.target.value)}
              className="bg-transparent border-none outline-none text-sm appearance-none cursor-pointer pr-4"
              style={{ color: '#c8d0e7' }}
            >
              <option value="All" style={{ background: '#0d1238' }}>All Criticalities</option>
              <option value="Low" style={{ background: '#0d1238' }}>Low</option>
              <option value="Medium" style={{ background: '#0d1238' }}>Medium</option>
              <option value="High" style={{ background: '#0d1238' }}>High</option>
            </select>
          </div>

          <div
            className="flex items-center gap-2 px-3 py-2 rounded-lg flex-shrink-0"
            style={{ background: '#080d2a', border: '1px solid #1a2555' }}
          >
            <input
              type="date"
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              className="bg-transparent border-none outline-none text-sm cursor-pointer"
              style={{ color: '#c8d0e7', colorScheme: 'dark' }}
            />
          </div>

          <div
            className="flex items-center gap-2 px-3 py-2 rounded-lg flex-shrink-0"
            style={{ background: '#080d2a', border: '1px solid #1a2555' }}
          >
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="bg-transparent border-none outline-none text-sm appearance-none cursor-pointer pr-4"
              style={{ color: '#c8d0e7' }}
            >
              <option value="All" style={{ background: '#0d1238' }}>All Types</option>
              <option value="Database" style={{ background: '#0d1238' }}>Database</option>
              <option value="Authentication" style={{ background: '#0d1238' }}>Authentication</option>
              <option value="Network" style={{ background: '#0d1238' }}>Network</option>
              <option value="Security" style={{ background: '#0d1238' }}>Security</option>
              <option value="System" style={{ background: '#0d1238' }}>System</option>
              <option value="Other" style={{ background: '#0d1238' }}>Other</option>
            </select>
          </div>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border px-3 py-2 text-sm" style={{ borderColor: 'rgba(239,68,68,0.5)', color: '#fecaca', background: 'rgba(127,29,29,0.25)' }}>
          {error}
        </div>
      )}

      {isLoading ? (
        <div
          className="px-6 py-12 text-center rounded-xl"
          style={{ background: '#0d1238', border: '1px solid #1a2555' }}
        >
          <p className="text-[14px] font-medium text-white">Loading anomalies...</p>
        </div>
      ) : logs.length === 0 ? (
        <div
          className="px-6 py-12 text-center rounded-xl"
          style={{ background: '#0d1238', border: '1px solid #1a2555' }}
        >
          <Radar size={32} style={{ color: '#3d4a7a', margin: '0 auto 12px' }} />
          <p className="text-[14px] font-medium text-white mb-1">
            Zero Anomalies Detected
          </p>
          <p className="text-[13px]" style={{ color: '#5a6498' }}>
            No anomalies found matching your criteria.
          </p>
        </div>
      ) : (
      <div
        className="rounded-xl overflow-hidden"
        style={{ background: '#0d1238', border: '1px solid #1a2555' }}
      >
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr style={{ borderBottom: '1px solid #1a2555' }}>
                {['ID', 'Timestamp', 'Criticality', 'Type', 'CPU %', 'RAM %', 'Project', 'Message'].map((h) => (
                  <th
                    key={h}
                    className="px-6 py-3.5 text-left text-[10px] font-bold uppercase tracking-[0.12em]"
                    style={{ color: '#3d4a7a' }}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y" style={{ divideColor: 'rgba(26,37,85,0.5)' }}>
              {logs.map((log) => {
                const crit = getCriticality(log.level);
                const cfg = critConfig[crit];
                return (
                  <tr
                    key={log.id}
                    className="transition-colors hover:bg-[rgba(13,18,56,0.8)]"
                  >
                    <td className="px-6 py-3 whitespace-nowrap text-[12px] font-mono" style={{ color: '#5a6498' }}>
                      {log.id}
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap text-[12px] font-mono" style={{ color: '#5a6498' }}>
                      {formatDate(log.timestamp)}
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap">
                      <span
                        className="inline-flex items-center gap-1.5 text-[10px] font-bold px-2 py-0.5 rounded"
                        style={{ background: cfg.bg, color: cfg.text }}
                      >
                        <span
                          className="w-1 h-1 rounded-full"
                          style={{ background: cfg.dot, boxShadow: `0 0 4px ${cfg.dot}` }}
                        />
                        {crit}
                      </span>
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap text-[12px]" style={{ color: '#7a84b3' }}>
                      {log.type || '-'}
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap text-[12px]" style={{ color: '#7a84b3' }}>
                      {log.cpu_percent ?? '-'}
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap text-[12px]" style={{ color: '#7a84b3' }}>
                      {log.ram_percent ?? '-'}
                    </td>
                    <td className="px-6 py-3 whitespace-nowrap text-[12px] font-medium" style={{ color: '#818cf8' }}>
                      {log.project_name || log.project_id || '-'}
                    </td>
                    <td className="px-6 py-3 text-[13px] font-mono break-words" style={{ color: '#e2e8f0', maxWidth: '300px' }}>
                      {log.message}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {totalItems > 0 && (
          <div className="px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-4" style={{ borderTop: '1px solid #1a2555' }}>
            <span className="text-[12px] font-medium" style={{ color: '#4a5490' }}>
              Showing {((currentPage - 1) * ITEMS_PER_PAGE) + 1} to {Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of {Number(totalItems).toLocaleString()} entries
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => handlePageChange(Math.max(1, currentPage - 1))}
                disabled={currentPage === 1 || isLoading}
                className="px-3 py-1.5 rounded text-[11px] font-bold transition-colors disabled:opacity-50 disabled:cursor-not-allowed hover:bg-[rgba(59,130,246,0.1)]"
                style={{ background: '#131b4d', color: '#7a84b3', border: '1px solid #1a2555' }}
              >
                Previous
              </button>
              <span className="text-[12px] font-medium px-2" style={{ color: '#c8d0e7' }}>
                Page {currentPage} of {totalPages}
              </span>
              <button
                onClick={() => handlePageChange(Math.min(totalPages, currentPage + 1))}
                disabled={currentPage === totalPages || isLoading}
                className="px-3 py-1.5 rounded text-[11px] font-bold transition-colors disabled:opacity-50 disabled:cursor-not-allowed hover:bg-[rgba(59,130,246,0.1)]"
                style={{ background: '#131b4d', color: '#7a84b3', border: '1px solid #1a2555' }}
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
      )}

      {/* Floating AI Diagnostic Assistant */}
      <AIDiagnosticAssistant />

      <style
        dangerouslySetInnerHTML={{
          __html: `
        .hide-scrollbar::-webkit-scrollbar {
          display: none;
        }
        .hide-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `,
        }}
      />
    </div>
  );
}
