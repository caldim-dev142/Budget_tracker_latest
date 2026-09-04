import { Controller, Get, Post, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { CardsService } from './cards.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('cards')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('cards')
export class CardsController {
  constructor(private readonly cardsService: CardsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all credit cards outstanding & ledger' })
  findAll(@Req() req: any) {
    return this.cardsService.findAll(req.user.householdId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new credit card ledger' })
  createCard(
    @Req() req: any,
    @Body('name') name: string,
    @Body('previousOutstandingPaise') previousOutstandingPaise: number,
  ) {
    return this.cardsService.createCard(req.user.householdId, name, previousOutstandingPaise);
  }

  @Post(':cardId/transactions')
  @ApiOperation({ summary: 'Add a credit card transaction' })
  addTransaction(
    @Req() req: any,
    @Param('cardId') cardId: string,
    @Body('description') description: string,
    @Body('amountPaise') amountPaise: number, // payment < 0, spend > 0
  ) {
    return this.cardsService.addTransaction(
      req.user.householdId,
      cardId,
      description,
      amountPaise,
    );
  }
}
