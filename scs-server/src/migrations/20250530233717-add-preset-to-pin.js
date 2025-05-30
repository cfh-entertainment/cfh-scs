'use strict';
module.exports = {
  async up(q, S) {
    await q.addColumn('Pins', 'presetId', {
      type: S.INTEGER,
      references: { model: 'PinPresets', key: 'id' },
      allowNull: true,
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    });
  },
  async down(q) { await q.removeColumn('Pins', 'presetId'); }
};
