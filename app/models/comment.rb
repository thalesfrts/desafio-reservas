class Comment < ApplicationRecord
  MAX_PHOTO_SIZE = 5.megabytes
  MAX_PHOTOS = 5
  ALLOWED_PHOTO_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/webp
    image/gif
    image/heic
    image/heif
  ].freeze

  belongs_to :ticket
  belongs_to :user
  has_many_attached :photos

  validates :body, presence: true
  validate :validate_photos

  private

  def validate_photos
    return unless photos.attached?

    if photos.count > MAX_PHOTOS
      errors.add(:photos, "permitem no maximo 5 imagens por comentario")
    end

    photos.each do |photo|
      unless ALLOWED_PHOTO_CONTENT_TYPES.include?(photo.content_type)
        errors.add(:photos, "devem conter apenas imagens (PNG, JPG, WEBP, GIF ou HEIC)")
      end

      if photo.byte_size > MAX_PHOTO_SIZE
        errors.add(:photos, "#{photo.filename} excede o limite de 5MB")
      end
    end
  end
end
