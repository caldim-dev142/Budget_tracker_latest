import { Controller, Get, Post, Body, Param, Delete, UseGuards, Query, Req, Patch } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { EntriesService } from './entries.service';
import { CreateEntryDto } from './dto/create-entry.dto';
import { UpdateEntryDto } from './dto/update-entry.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('entries')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('entries')
export class EntriesController {
  constructor(private readonly entriesService: EntriesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all entries for a specific year-month' })
  findByMonth(@Req() req: any, @Query('yearMonth') yearMonth: string) {
    return this.entriesService.findByMonth(req.user.householdId, yearMonth);
  }

  @Post('batch')
  @ApiOperation({ summary: 'Sync batch of entries' })
  upsertBatch(@Req() req: any, @Body() entries: CreateEntryDto[]) {
    return this.entriesService.upsertBatch(req.user.householdId, entries, req.user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get entry by ID' })
  findById(@Req() req: any, @Param('id') id: string) {
    return this.entriesService.findById(id, req.user.householdId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft delete entry by ID' })
  softDelete(@Req() req: any, @Param('id') id: string) {
    return this.entriesService.softDelete(id, req.user.householdId);
  }
}
