'use client'

import React, { useState, useEffect } from 'react'
import dynamic from 'next/dynamic'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import { useTheme } from '@mui/material/styles'
import { attendanceService } from '@/libs/attendanceService'

const Chart = dynamic(() => import('react-apexcharts'), { ssr: false })

const getMonthName = (month: number) => {
  const months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ]
  return months[month - 1] || `Bulan ${month}`
}

const statusColors = {
  present: '#4CAF50',     // Green
  late: '#FF9800',        // Orange
  working: '#3F51B5',     // Indigo
  leave_sick: '#03A9F4',  // Light Blue
  not_yet: '#9E9E9E',     // Grey
  absent: '#F44336',      // Red
  early_leave: '#9C27B0'  // Purple
}

interface AttendanceChartsProps {
  period: string
  month: number
  year: number
}

const AttendanceCharts = ({ period, month, year }: AttendanceChartsProps) => {
  const theme = useTheme()
  const [stats, setStats] = useState<any>(null)
  const [trendData, setTrendData] = useState<any>({ labels: [], data: [] })

  // Define explicit theme colors to avoid ApexCharts processing errors
  const isDark = theme.palette.mode === 'dark'
  const textColorPrimary = isDark ? '#E2E8F0' : '#475569'
  const textColorSecondary = isDark ? '#94A3B8' : '#64748B'
  const textColorMuted = isDark ? '#64748B' : '#94A3B8'

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [summary, trend] = await Promise.all([
          attendanceService.getDetailedSummary({ filter: period, month, year }),
          attendanceService.getAttendanceTrend({ filter: period, month, year })
        ])
        setStats(summary)
        setTrendData(trend)
      } catch (error) {
        console.error('Error fetching charts data:', error)
      }
    }
    fetchData()
  }, [period, month, year])

  // Detailed rows for the "Ringkasan Kehadiran" sidebar
  const detailedStats = [
    { label: 'Hadir Tepat Waktu', count: stats?.present || 0, color: statusColors.present },
    { label: 'Terlambat', count: stats?.late || 0, color: statusColors.late },
    { label: 'Sedang Bekerja', count: stats?.working || 0, color: statusColors.working },
    { label: 'Izin/Sakit', count: stats?.leave_sick || 0, color: statusColors.leave_sick },
    { label: 'Belum Hadir', count: stats?.not_yet || 0, color: statusColors.not_yet },
    { label: 'Alpha', count: stats?.absent || 0, color: statusColors.absent },
    { label: 'Pulang di Jam Kerja', count: stats?.early_leave || 0, color: statusColors.early_leave },
  ]

  const donutOptions = {
    labels: [
      'Hadir Tepat Waktu', 
      'Terlambat', 
      'Sedang Bekerja', 
      'Izin/Sakit', 
      'Belum Hadir', 
      'Alpha', 
      'Pulang di Jam Kerja'
    ],
    colors: [
        statusColors.present,
        statusColors.late,
        statusColors.working,
        statusColors.leave_sick,
        statusColors.not_yet,
        statusColors.absent,
        statusColors.early_leave
    ],
    legend: { 
      position: 'bottom',
      fontSize: '13px',
      markers: { radius: 2 },
      labels: { colors: textColorPrimary }
    },
    stroke: { show: false },
    dataLabels: { enabled: false },
    plotOptions: { 
      pie: { 
        donut: { 
          size: '75%',
          labels: {
            show: true,
            name: {
              show: true,
              fontSize: '14px',
              color: textColorSecondary,
              offsetY: -10
            },
            value: {
              show: true,
              fontSize: '22px',
              fontWeight: 600,
              color: textColorPrimary,
              offsetY: 4,
              formatter: (val: string) => val
            },
            total: {
                show: true,
                label: 'Karyawan',
                fontSize: '14px',
                color: textColorSecondary,
                formatter: () => stats?.total || 0
            }
          }
        } 
      } 
    }
  }

  const donutSeries = [
    stats?.present || 0,
    stats?.late || 0,
    stats?.working || 0,
    stats?.leave_sick || 0,
    stats?.not_yet || 0,
    stats?.absent || 0,
    stats?.early_leave || 0
  ]

  const lineSeries = [
    { name: 'Hadir Tepat Waktu', data: trendData.present || [] },
    { name: 'Terlambat', data: trendData.late || [] },
    { name: 'Alpha', data: trendData.absent || [] },
    { name: 'Izin/Sakit', data: trendData.leave_sick || [] },
    { name: 'Pulang di Jam Kerja', data: trendData.early_leave || [] }
  ]

  const lineOptions = {
    chart: { toolbar: { show: false } },
    stroke: { curve: 'smooth', width: 3 },
    colors: [
        statusColors.present,
        statusColors.late,
        statusColors.absent,
        statusColors.leave_sick,
        statusColors.early_leave
    ],
    fill: {
        type: 'gradient',
        gradient: { shadeIntensity: 1, opacityFrom: 0.5, opacityTo: 0.1, stops: [0, 90, 100] }
    },
    xaxis: { 
        categories: trendData.labels || [],
        axisBorder: { show: false },
        axisTicks: { show: false },
        labels: {
          style: { colors: textColorSecondary, fontSize: '12px' }
        }
    },
    yaxis: {
        min: 0,
        forceNiceScale: true,
        labels: { 
          style: { colors: textColorSecondary, fontSize: '12px' },
          formatter: (val: number) => Math.round(val) 
        }
    },
    tooltip: { 
      theme: isDark ? 'dark' : 'light',
      y: { formatter: (val: number) => `${val} Karyawan` } 
    },
    legend: { 
      position: 'top', 
      horizontalAlign: 'right',
      labels: { colors: textColorPrimary }
    }
  }

  const getTrendTitle = () => {
    if (period === 'today') return 'Tren Kedatangan Hari Ini (Per Jam)'
    if (period === 'week') return 'Tren Kehadiran (7 Hari Terakhir)'
    if (period === 'month') return `Tren Kehadiran Bulanan (${getMonthName(month)})`
    return `Tren Kehadiran Tahunan (${year})`
  }

  return (
    <Grid container spacing={6}>
      {/* 1. Ringkasan Kehadiran List (Fixing the center gap) */}
      <Grid item xs={12} md={3}>
        <Card sx={{ height: '100%', minHeight: 400 }}>
             <CardContent>
                 <div className="flex justify-between items-center mb-4">
                     <Typography variant="h6" fontWeight="bold">Ringkasan Kehadiran</Typography>
                     <Typography variant="caption" color="text.secondary">
                        {period === 'today' ? 'Hari Ini' : period === 'month' ? `${getMonthName(month)} ${year}` : `Tahun ${year}`}
                     </Typography>
                 </div>
                 <Typography variant="body2" color="text.secondary" sx={{ mb: 6 }}>
                    Status kehadiran karyawan {period === 'today' ? 'hari ini' : period === 'month' ? 'bulan ini' : 'tahun ini'}
                 </Typography>
                 
                 <div className="flex flex-col gap-5">
                    {detailedStats.map((item, idx) => (
                        <div key={idx} className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <span style={{ width: 12, height: 12, borderRadius: '2px', backgroundColor: item.color }}></span>
                                <Typography variant="body2" sx={{ color: textColorPrimary }}>{item.label}</Typography>
                            </div>
                            <Typography variant="body2" fontWeight="bold" sx={{ color: textColorPrimary }}>{item.count}</Typography>
                        </div>
                    ))}
                 </div>
             </CardContent>
         </Card>
      </Grid>

      {/* 2. Trends Chart */}
      <Grid item xs={12} md={6}>
        <Card sx={{ height: '100%' }}>
          <CardHeader title={getTrendTitle()} subheader='Data persentase kehadiran berdasarkan periode' />
          <CardContent>
            <Chart 
              type='area' 
              height={300} 
              series={lineSeries}
              options={lineOptions as any} 
            />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 3. Distribution Chart */}
      <Grid item xs={12} md={3}>
        <Card sx={{ height: '100%' }}>
          <CardHeader 
            title='Status Kehadiran' 
            subheader={period === 'today' ? 'Proporsi real-time hari ini' : `Proporsi periode ${period === 'month' ? getMonthName(month) : 'tahun ' + year}`} 
          />
          <CardContent className="flex justify-center">
            <Chart type='donut' height={340} options={donutOptions as any} series={donutSeries} />
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}

export default AttendanceCharts
