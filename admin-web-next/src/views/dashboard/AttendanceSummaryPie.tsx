// src/views/dashboard/AttendanceSummaryPie.tsx
'use client'

import dynamic from 'next/dynamic'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import IconButton from '@mui/material/IconButton'
import type { ApexOptions } from 'apexcharts'
import { DashboardSummary } from '@/libs/dashboardService'
import { useState, useEffect } from 'react'

const AppReactApexCharts = dynamic(() => import('@/libs/styles/AppReactApexCharts'))

interface Props {
  summary: DashboardSummary | null
  onRefresh: () => void
}

const AttendanceSummaryPie = ({ summary, onRefresh }: Props) => {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])
  const pieOptions: ApexOptions = {
    labels: ['Hadir Tepat Waktu', 'Terlambat', 'Alpha', 'Izin/Sakit', 'Sedang Bekerja', 'Pulang di jam kerja', 'Terlambat & Pulang di Jam Kerja', 'Belum Hadir'],
    colors: ['#22C55E', '#FBBF24', '#EF4444', '#0EA5E9', '#6366F1', '#F97316', '#D946EF', '#94A3B8'],
    legend: { show: false },
    dataLabels: { enabled: false },
    stroke: { width: 0 },
    plotOptions: {
      pie: {
        donut: {
          size: '75%',
          labels: {
            show: true,
            total: {
              show: true,
              label: 'Karyawan',
              formatter: () => summary?.total.toString() || '0'
            }
          }
        }
      }
    }
  }

  const pieSeries = summary ? [
    summary.present,
    summary.late,
    summary.absent,
    (summary.leave || 0) + (summary.sick || 0),
    summary.working,
    summary.early_leave,
    summary.late_early_leave,
    summary.not_yet
  ] : []

  return (
    <Card className='shadow-lg rounded-3xl h-full border-none'>
        <CardContent className='p-6'>
            <Box className='flex justify-between items-center mbe-8'>
                <Box>
                    <Typography variant='h6' className='font-bold text-slate-800 uppercase text-sm tracking-widest'>Ringkasan Kehadiran</Typography>
                    <Typography variant='caption' className='text-slate-400'>Statistik kehadiran karyawan hari ini</Typography>
                </Box>
                <IconButton size='small' onClick={onRefresh}>
                    <i className='ri-refresh-line text-slate-400' />
                </IconButton>
            </Box>
            <Box className='flex flex-col items-center justify-center min-h-[300px] w-full'>
                {isMounted && summary ? (
                    <AppReactApexCharts type='donut' width='100%' height={300} options={pieOptions} series={pieSeries} />
                ) : (
                    <Box className='h-[300px] flex flex-col items-center justify-center gap-4'>
                        <i className='ri-loader-4-line animate-spin text-3xl text-blue-500' />
                        <Typography className='text-slate-400 text-xs italic'>Memuat data ringkasan...</Typography>
                    </Box>
                )}
                <Grid container spacing={2} className='mbs-6'>
                    {[
                        { color: 'bg-[#22C55E]', label: 'Hadir', val: summary?.present },
                        { color: 'bg-[#FBBF24]', label: 'Telat', val: summary?.late },
                        { color: 'bg-[#EF4444]', label: 'Alpha', val: summary?.absent },
                        { color: 'bg-[#0EA5E9]', label: 'Izin', val: (summary?.leave || 0) + (summary?.sick || 0) },
                        { color: 'bg-[#6366F1]', label: 'Bekerja', val: summary?.working },
                        { color: 'bg-[#F97316]', label: 'Pulang JK', val: summary?.early_leave },
                        { color: 'bg-[#D946EF]', label: 'Terlambat & Pulang di Jam Kerja', val: summary?.late_early_leave },
                        { color: 'bg-[#94A3B8]', label: 'Belum Hadir', val: summary?.not_yet }
                    ].map((item, idx) => (
                        <Grid item xs={6} key={idx}>
                            <Box className='flex items-center gap-2 p-2 rounded-xl bg-slate-50 border border-slate-100'>
                                <Box className={`w-2.5 h-2.5 rounded-full`} style={{ backgroundColor: item.color.replace('bg-[', '').replace(']', '') }} />
                                <Typography className='text-[10px] text-slate-600 whitespace-nowrap'>{item.label}: <b className='text-slate-800 ml-1'>{item.val || 0}</b></Typography>
                            </Box>
                        </Grid>
                    ))}
                </Grid>
            </Box>
        </CardContent>
    </Card>
  )
}

export default AttendanceSummaryPie
