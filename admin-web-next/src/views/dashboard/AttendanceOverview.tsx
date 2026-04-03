'use client'

import React from 'react'
import dynamic from 'next/dynamic'
import Card from '@mui/material/Card'
import { useTheme } from '@mui/material/styles'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'

const Chart = dynamic(() => import('react-apexcharts'), { ssr: false })

const AttendanceOverview = () => {
  const theme = useTheme()

  const options = {
    chart: {
      parentHeightOffset: 0,
      toolbar: { show: false }
    },
    plotOptions: {
      bar: {
        borderRadius: 8,
        columnWidth: '40%',
        endingShape: 'rounded',
        startingShape: 'rounded'
      }
    },
    dataLabels: { enabled: false },
    grid: {
      show: true,
      strokeDashArray: 7,
      padding: {
        top: -10,
        bottom: -10,
        left: 0,
        right: 0
      }
    },
    colors: [theme.palette.primary.main, theme.palette.secondary.main],
    xaxis: {
      categories: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
      axisBorder: { show: false },
      axisTicks: { show: false }
    },
    yaxis: { show: false }
  }

  const series = [
    {
      name: 'Hadir',
      data: [45, 52, 48, 61, 55, 10, 5]
    },
    {
      name: 'Izin/Alpa',
      data: [5, 3, 7, 2, 8, 0, 0]
    }
  ]

  return (
    <Card sx={{ height: '100%' }}>
      <CardHeader
        title='Overview Kehadiran Mingguan'
        titleTypographyProps={{ variant: 'h6' }}
        subheader='Berdasarkan 7 hari terakhir'
      />
      <CardContent>
        <Chart type='bar' height={300} options={options as any} series={series} />
      </CardContent>
    </Card>
  )
}

export default AttendanceOverview
