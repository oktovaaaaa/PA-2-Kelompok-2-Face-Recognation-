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
    labels: ['Hadir Tepat Waktu', 'Terlambat', 'Alpha', 'Izin/Sakit', 'Sedang Bekerja', 'Pulang Awal', 'Belum Hadir'],
    colors: ['#4CAF50', '#FF9800', '#F44336', '#03A9F4', '#3F51B5', '#9C27B0', '#9E9E9E'],
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
            <Box className='flex flex-col items-center justify-center min-h-[300px]'>
                {isMounted ? (
                    <AppReactApexCharts type='donut' width='100%' height={300} options={pieOptions} series={pieSeries} />
                ) : (
                    <Box className='h-[300px] flex items-center justify-center'>
                        <i className='ri-loader-4-line animate-spin text-2xl text-slate-200' />
                    </Box>
                )}
                <Grid container spacing={2} className='mbs-6'>
                    {[
                        { color: 'bg-[#4CAF50]', label: 'Hadir', val: summary?.present },
                        { color: 'bg-[#FF9800]', label: 'Telat', val: summary?.late },
                        { color: 'bg-[#F44336]', label: 'Alpha', val: summary?.absent },
                        { color: 'bg-[#03A9F4]', label: 'Izin', val: (summary?.leave || 0) + (summary?.sick || 0) },
                        { color: 'bg-[#3F51B5]', label: 'Bekerja', val: summary?.working },
                        { color: 'bg-[#9C27B0]', label: 'Pulang Awal', val: summary?.early_leave },
                        { color: 'bg-[#9E9E9E]', label: 'Belum Hadir', val: summary?.not_yet }
                    ].map((item, idx) => (
                        <Grid item xs={6} md={4} key={idx}>
                            <Box className='flex items-center gap-2 p-2 rounded-xl bg-slate-50'>
                                <Box className={`w-2 h-2 rounded-full`} style={{ backgroundColor: item.color.replace('bg-', '') }} />
                                <Typography className='text-[10px] whitespace-nowrap'>{item.label}: <b>{item.val || 0}</b></Typography>
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
